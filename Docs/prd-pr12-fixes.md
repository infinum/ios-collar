# PRD: PR #12 Review Fixes — Add Swift 6 Support

**Branch:** `add-swift-6-support`  
**Reviewer:** kjaklinovic  
**Date:** 2026-04-24  
**Type:** Breaking change (version bump required)

---

## 1. Introduction / Overview

PR #12 adds Swift 6 compiler support to the Collar analytics library. The reviewer (kjaklinovic) identified four code quality issues that must be resolved before merge:

1. Synchronous `logs` access blocks the main thread
2. Strong `self` capture in `queue.async` closures
3. `ISO8601DateFormatter` re-initialized on every `LogItem.description` call
4. SwiftUI `updateLogs()` calls the blocking `logs` property from the main thread

These are surgical fixes — no architectural changes, no new abstractions beyond what each fix strictly requires.

---

## 2. Goals

- Eliminate all main-thread blocking caused by synchronous `queue.sync` calls in UI paths
- Follow Swift memory management best practices (`[weak self]` in async closures)
- Remove repeated allocation of expensive `ISO8601DateFormatter` objects
- All existing functionality must continue to work after the changes

---

## 3. User Stories

- **As a library consumer**, I want `logs` to be fetched asynchronously so it never freezes the UI.
- **As a library maintainer**, I want async closures to use `[weak self]` so the code follows standard Swift memory safety patterns.
- **As a library consumer**, I want `LogItem.description` to be cheap to call so it doesn't create hidden performance costs.

---

## 4. Functional Requirements

### Fix 1 — Make `logs` async (`AnalyticsCollectionManager.swift:31–33`)

**Problem:** `public var logs: [LogItem] { queue.sync { _logs } }` blocks the calling thread with a synchronous queue hop. Called from UI contexts, this stalls the main thread.

**Change:** Replace the sync computed property with an async computed property using `withCheckedContinuation`.

```swift
// Before
public var logs: [LogItem] {
    queue.sync { _logs }
}

// After
public var logs: [LogItem] {
    get async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: _logs)
            }
        }
    }
}
```

> **Breaking change:** All call sites must now `await analyticsManager.logs`.  
> **Tradeoff:** Consumers who currently call `logs` synchronously must wrap calls in `Task { }` or `async` contexts. This is intentional and acceptable given the version bump.

**Success criteria:**
- `logs` property compiles with `async` keyword
- No `queue.sync` calls remain in `AnalyticsCollectionManager`
- All existing call sites updated to `await`

---

### Fix 2 — Use `[weak self]` in all `queue.async` closures (`AnalyticsCollectionManager.swift:39, 48, 62, 72, 83`)

**Problem:** Closures use `[self]` (strong capture). While the singleton won't leak, strong capture in async closures is against Swift convention and masks real patterns.

**Change:** Replace `[self]` with `[weak self]` and add `guard let self else { return }` in every `queue.async` closure body.

Affected methods: `clearLogs()`, `clearLog(_:)`, `track(screenName:screenClass:)`, `setUserProperty(_:forName:)`, `log(event:timestamp:parameters:)`.

```swift
// Before
queue.async { [self] in
    _logs.removeAll()
    postUpdateNotification()
}

// After
queue.async { [weak self] in
    guard let self else { return }
    _logs.removeAll()
    postUpdateNotification()
}
```

**Success criteria:**
- Zero `[self]` capture lists remain in `AnalyticsCollectionManager`
- Every `queue.async` closure has `[weak self]` + `guard let self else { return }`

---

### Fix 3 — Static `ISO8601DateFormatter` in `LogItem` (`LogItem.swift:49`)

**Problem:** `LogItem.description` creates a new `ISO8601DateFormatter()` on every call. `ISO8601DateFormatter` is expensive to initialize (internally allocates a `Calendar`, locale data, etc.).

**Change:** Add a private static lazy formatter to `LogItem`.

```swift
// Before (inside `description`)
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

// After — add at type level
private static let iso8601Formatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

// Updated usage inside `description`
lines.append("Timestamp: \(LogItem.iso8601Formatter.string(from: timestamp))")
```

> **Note:** `ISO8601DateFormatter` is thread-safe for concurrent reads once configured, so a `static` instance is safe here.

**Success criteria:**
- `ISO8601DateFormatter()` is initialized exactly once (static)
- `description` uses the static instance
- No other formatter allocations introduced

---

### Fix 4 — Async `updateLogs()` in `LogListView` (`LogListView.swift:124`)

**Problem:** `updateLogs()` calls `analyticsManager.logs` synchronously from the main thread (triggered by `.onAppear` and `.onReceive`). After Fix 1, `logs` is `async`, so this must be updated.

**Change:** Make `updateLogs()` async and wrap all call sites in `Task { }`.

```swift
// Before
private func updateLogs() {
    items = analyticsManager.logs.sorted(by: { $0.timestamp > $1.timestamp })
}

// Called as:
.onReceive(...) { _ in updateLogs() }
.onAppear(perform: updateLogs)

// After
private func updateLogs() async {
    items = await analyticsManager.logs.sorted(by: { $0.timestamp > $1.timestamp })
}

// Called as:
.onReceive(...) { _ in Task { await updateLogs() } }
.onAppear { Task { await updateLogs() } }
```

> **Note:** `Task { }` inherits the actor context from its creation site. Since SwiftUI view modifiers run on the `@MainActor`, the `items` `@State` assignment inside `updateLogs()` remains on the main actor — no `DispatchQueue.main` needed.

**Success criteria:**
- `updateLogs()` is `async`
- `.onAppear` and `.onReceive` wrap the call in `Task { await ... }`
- No `queue.sync` or main-thread blocking path remains in the UI layer

---

## 5. Non-Goals (Out of Scope)

- Migrating `AnalyticsCollectionManager` to Swift `actor` — this is a larger refactor; the `DispatchQueue`-based approach is sufficient
- Changing the `NotificationCenter`-based update mechanism to `AsyncStream` or `Combine`
- Fixing the duplicate `matchesSearch` computation in `LogListView.filteredItems` (unrelated to this PR's issues)
- Adding new tests (test suite not currently present for these files)

---

## 6. Technical Considerations

| Item | Detail |
|---|---|
| Swift version | Swift 6 (`add-swift-6-support` branch) |
| Concurrency model | `DispatchQueue` serial queue + `withCheckedContinuation` bridge |
| Breaking change | `logs` property gains `async` — callers must `await` |
| Thread safety | `ISO8601DateFormatter` static instance is safe (read-only after init) |
| SwiftUI | `Task { }` in `.onAppear` / `.onReceive` preserves `@MainActor` context |

---

## 7. Implementation Order

Apply fixes in this order to minimize conflicts:

```
1. Fix 3 (DateFormatter) → verify: description compiles, formatter is static
2. Fix 2 (weak self)     → verify: no [self] captures remain
3. Fix 1 (async logs)    → verify: property is async, compiles
4. Fix 4 (SwiftUI)       → verify: updateLogs is async, Task wraps call sites
```

Fix 3 and Fix 2 are independent and can be done in either order. Fix 4 depends on Fix 1 being done first.

---

## 8. Success Metrics

- [ ] Project builds with Swift 6 compiler, zero warnings in changed files
- [ ] No `queue.sync` calls remain in `AnalyticsCollectionManager`
- [ ] No `[self]` capture lists remain in `AnalyticsCollectionManager`
- [ ] `ISO8601DateFormatter` allocated exactly once (static)
- [ ] `updateLogs()` is `async`, all call sites use `Task { await ... }`
- [ ] `Collar.podspec` and `Package.swift` version is `2.0.0`
- [ ] PR review comments from kjaklinovic marked as resolved

---

## 9. README Update (Required)

The README already contains a `## ⚠️ Breaking Changes in v2.0.0` section and migration guide. However, it incorrectly states:

> "The manager is now an `actor` providing compiler-verified thread safety"

This is **wrong** — the implementation keeps the `DispatchQueue`-based approach. The README must be corrected before merge.

**Required README changes:**

- Remove the claim that `AnalyticsCollectionManager` is now an `actor`
- Remove the notification threading note about "actor's queue" — notifications are still posted on the internal serial `DispatchQueue`, not an actor executor. The advice to use `Task { @MainActor in ... }` in observers remains valid and should stay.
- Only `logs` (the read property) is `async`. Remove `await` from all write/clear calls: `log(event:)`, `setUserProperty(_:forName:)`, `track(screenName:)`, `clearLogs()`, and `clearLog(_:)`. These dispatch fire-and-forget onto the internal queue and are not `async`.
- Keep `await logs` — the read property is correctly `async`.
- Keep `await showLogs(from:)` — this method is `@MainActor`, and calling it from a non-isolated `Task` correctly requires `await` in Swift 6.

**Corrected usage example for writes (these remain synchronous fire-and-forget):**

```swift
// These are NOT async — they dispatch internally
AnalyticsCollectionManager.shared.log(event: "some_event", parameters: [...])
AnalyticsCollectionManager.shared.setUserProperty("value", forName: "key")
AnalyticsCollectionManager.shared.track(screenName: "Home", screenClass: "HomeVC")
```

**Success criteria for README:**
- [ ] No mention of `actor` in breaking changes or migration sections
- [ ] `log(event:)`, `setUserProperty`, `track`, `clearLogs()`, `clearLog(_:)` shown without `await`
- [ ] `logs` read property shown with `await`
- [ ] `showLogs(from:)` keeps `await` (it is `@MainActor`, requires `await` from non-isolated `Task`)
- [ ] Notification observer example kept (threading note is still accurate)

---

## 10. Decisions Log

| Question | Decision |
|---|---|
| Rename `logs` to `fetchLogs()`? | **No** — keep as `logs` property, minimize diff |
| Document breaking change in README? | **Yes** — README already has section, fix inaccuracies per §9 |
| Should `clearLogs()` / `clearLog(_:)` also be `async`? | **No** — reviewer comment targets the `logs` read property only; writes remain fire-and-forget dispatches |
| Does `showLogs(from:)` need `await` removed from README? | **No** — it is `@MainActor`; `await` is required in Swift 6 when called from a non-isolated `Task` |
| Version bump scope? | `Collar.podspec` and `Package.swift` already at `2.0.0` on this branch; no further bump needed |
