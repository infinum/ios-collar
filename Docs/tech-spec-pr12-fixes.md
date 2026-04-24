# Technical Specification: PR #12 Review Fixes — Add Swift 6 Support

**Branch:** `add-swift-6-support`  
**Author:** petar-jadek  
**Reviewer:** kjaklinovic  
**Date:** 2026-04-24  
**Status:** Ready for implementation

---

## 1. Scope

Four targeted fixes to `AnalyticsCollectionManager.swift`, `LogItem.swift`, `LogListView.swift`, and `README.md`. No architectural changes. No new abstractions beyond what each fix strictly requires.

**Version:** `Collar.podspec` and `Package.swift` are already at `2.0.0` on this branch. No further version bump is needed; confirming this in the success criteria is sufficient.

**Confirmed decisions:**
- `clearLogs()` and `clearLog(_:)` stay synchronous (fire-and-forget into the queue) — the reviewer's async comment targets only the `logs` read property.
- `showLogs(from:)` is `@MainActor` (not `async`). Calling it from a non-isolated `Task` requires `await` in Swift 6 — the README example is correct and must not be changed.

---

## 2. Current State

### `AnalyticsCollectionManager.swift`
- **L31–33:** `logs` is a synchronous computed property using `queue.sync`, blocking the calling thread.
- **L39, 48, 62, 72, 83:** All `queue.async` closures use `[self]` (strong capture).

### `LogItem.swift`
- **L49–50:** `description` creates a new `ISO8601DateFormatter()` on every invocation.

### `LogListView.swift`
- **L123–125:** `updateLogs()` is a synchronous function calling `analyticsManager.logs` directly.
- **L53:** `.onReceive` calls `updateLogs()` synchronously.
- **L54:** `.onAppear` calls `updateLogs` synchronously.

### `README.md`
- **L44:** Claims `AnalyticsCollectionManager` is now an `actor` — **false**.
- **L57–67:** Shows `await` on write methods (`log`, `setUserProperty`, `track`) — **incorrect**, they are fire-and-forget.
- **L117:** Says notifications are posted on "actor's queue" — **incorrect**, they are posted on the internal serial `DispatchQueue`.

---

## 3. Implementation Plan

Apply in this order (Fix 3 and Fix 2 are independent; Fix 4 depends on Fix 1):

```
1. Fix 3 — Static ISO8601DateFormatter   → verify: no per-call allocations in description
2. Fix 2 — [weak self] in queue.async    → verify: zero [self] captures remain
3. Fix 1 — Make `logs` async             → verify: property compiles as async, no queue.sync
4. Fix 4 — Async updateLogs() in SwiftUI → verify: updateLogs() is async, Task wraps call sites
5. Fix 5 — Correct README               → verify: no actor claims, correct await usage shown
```

---

## 4. Fix Details

### Fix 3 — Static `ISO8601DateFormatter` in `LogItem`

**File:** `Sources/Collar/Classes/Collar/LogItem.swift`

**Problem:** `description` (L49–50) allocates a new `ISO8601DateFormatter` on every call. `ISO8601DateFormatter` is expensive — it internally allocates `Calendar` and locale data on each init.

**Change:** Add a private `static` lazy instance at type level. Replace inline allocation with a reference to it.

```swift
// Add at type level, before `description`:
private static let iso8601Formatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

// Replace lines 49–51 inside `description`:
// Before:
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
lines.append("Timestamp: \(formatter.string(from: timestamp))")

// After:
lines.append("Timestamp: \(LogItem.iso8601Formatter.string(from: timestamp))")
```

**Thread safety:** `ISO8601DateFormatter` is safe for concurrent reads once configured. The `static` instance is initialized once and never mutated, so no lock is needed.

**Success criteria:**
- [ ] `ISO8601DateFormatter()` initializer appears exactly once in `LogItem.swift` (inside the static closure)
- [ ] `description` uses `LogItem.iso8601Formatter` instead of a local `formatter`
- [ ] File compiles with Swift 6

---

### Fix 2 — `[weak self]` in all `queue.async` closures

**File:** `Sources/Collar/Classes/Collar/AnalyticsCollectionManager.swift`

**Problem:** Five `queue.async` closures (L39, 48, 62, 72, 83) use `[self]` (strong capture). While the singleton pattern prevents leaks today, strong capture in async closures is non-idiomatic Swift and masks memory management intent.

**Affected methods:** `clearLogs()`, `clearLog(_:)`, `track(screenName:screenClass:)`, `setUserProperty(_:forName:)`, `log(event:timestamp:parameters:)`.

**Change:** Replace `[self]` with `[weak self]` and add `guard let self else { return }` at the top of each closure body.

```swift
// Before (example from clearLogs):
queue.async { [self] in
    _logs.removeAll()
    postUpdateNotification()
}

// After:
queue.async { [weak self] in
    guard let self else { return }
    _logs.removeAll()
    postUpdateNotification()
}
```

Apply the same pattern to all five affected closures.

**Success criteria:**
- [ ] Zero `[self]` capture lists remain in `AnalyticsCollectionManager.swift`
- [ ] Every `queue.async` closure has `[weak self]` + `guard let self else { return }`
- [ ] File compiles with Swift 6

---

### Fix 1 — Make `logs` an `async` computed property

**File:** `Sources/Collar/Classes/Collar/AnalyticsCollectionManager.swift`

**Problem:** `logs` (L31–33) blocks the calling thread via `queue.sync`. From UI contexts this stalls the main thread.

**Change:** Replace the synchronous computed property with an async computed property using `withCheckedContinuation` to bridge the `DispatchQueue` into Swift concurrency.

```swift
// Before:
public var logs: [LogItem] {
    queue.sync { _logs }
}

// After:
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

**Breaking change:** All call sites must now `await analyticsManager.logs`. The only internal call site is `LogListView.updateLogs()`, which is handled in Fix 4.

**Success criteria:**
- [ ] `logs` is declared with `get async`
- [ ] No `queue.sync` calls remain anywhere in `AnalyticsCollectionManager.swift`
- [ ] File compiles with Swift 6

---

### Fix 4 — Async `updateLogs()` in `LogListView`

**File:** `Sources/Collar/Classes/List/SwiftUI/LogListView.swift`

**Problem:** `updateLogs()` (L123–125) calls `analyticsManager.logs` synchronously. After Fix 1, `logs` is `async`, so this won't compile and must be updated. Both call sites (L53 `.onReceive`, L54 `.onAppear`) pass `updateLogs` as a synchronous function reference.

**Change:** Make `updateLogs()` an `async` function. Wrap both call sites in `Task { }`.

```swift
// Before:
private func updateLogs() {
    items = analyticsManager.logs.sorted(by: { $0.timestamp > $1.timestamp })
}

// Called as:
.onReceive(NotificationCenter.default.publisher(for: notificationName)) { _ in updateLogs() }
.onAppear(perform: updateLogs)

// After:
private func updateLogs() async {
    items = await analyticsManager.logs.sorted(by: { $0.timestamp > $1.timestamp })
}

// Called as:
.onReceive(NotificationCenter.default.publisher(for: notificationName)) { _ in Task { await updateLogs() } }
.onAppear { Task { await updateLogs() } }
```

**Threading note:** `Task { }` created in SwiftUI view modifier closures inherits `@MainActor` context. The `items` `@State` write inside `updateLogs()` therefore remains on the main actor — no explicit `DispatchQueue.main` dispatch is required.

**Success criteria:**
- [ ] `updateLogs()` is declared `async`
- [ ] `.onAppear` uses a closure with `Task { await updateLogs() }`
- [ ] `.onReceive` uses a closure with `Task { await updateLogs() }`
- [ ] No synchronous call to `analyticsManager.logs` remains in `LogListView.swift`
- [ ] File compiles with Swift 6

---

### Fix 5 — Correct `README.md`

**File:** `README.md`

**Problems identified against current code:**

| Line | Current text | Issue |
|------|-------------|-------|
| L44 | "The manager is now an `actor`..." | False — it is a `final class` with a `DispatchQueue` |
| L57–67 | `await` on `log(event:)`, `setUserProperty`, `track` | Not async — fire-and-forget dispatches |
| L88–89 | `await showLogs(from: viewController)` | Correct — `@MainActor` requires `await` from non-isolated `Task` in Swift 6; no change |
| L107 | `await clearLogs()` / `await clearLog(logItem)` | Not async — fire-and-forget dispatches; remove `await` |
| L117 | "Notification is posted on actor's queue" | No actor — posted on internal serial `DispatchQueue` |
| L139–149 | `await log(event:)` in migration guide | Not async; remove `await` |

**Required changes:**

1. **Remove L44** — delete the actor claim from the Breaking Changes bullet list.

2. **Fix write call examples (L51–67, L107, L139–149)** — remove `await` from all fire-and-forget write/clear calls:

```swift
// Correct — no await on writes or clears:
AnalyticsCollectionManager.shared.log(event: "some_event", parameters: [...])
AnalyticsCollectionManager.shared.setUserProperty("some_value", forName: "user_property_key")
AnalyticsCollectionManager.shared.track(screenName: "Home", screenClass: "HomeViewController")
AnalyticsCollectionManager.shared.clearLogs()
AnalyticsCollectionManager.shared.clearLog(logItem)
```

3. **Fix notification threading note (L117)** — replace "actor's queue" with "internal serial DispatchQueue". The `Task { @MainActor in }` guidance is still correct and must stay.

4. **Reads remain async** — the `logs` read example (`let logs = await ...`) is correct and must stay.

5. **`showLogs(from:)` is correct** — `@MainActor` function; `await` inside a non-isolated `Task` is required in Swift 6. Do not change.

**Success criteria:**
- [ ] No occurrence of the word "actor" in the Breaking Changes or Migration sections
- [ ] `log`, `setUserProperty`, `track`, `clearLogs`, `clearLog` shown without `await`
- [ ] `logs` read property shown with `await`
- [ ] `showLogs(from:)` still shown with `await` inside `Task { }`
- [ ] Notification observer threading note preserved, referencing "internal serial DispatchQueue" not "actor's queue"

---

## 5. Out of Scope

- Migrating `AnalyticsCollectionManager` to a Swift `actor`
- Replacing `NotificationCenter` with `AsyncStream` or `Combine`
- Fixing the duplicate `matchesSearch` computation in `LogListView.filteredItems` (L25–36) — unrelated to this PR; note it in a follow-up issue instead
- Adding tests (no test target currently covers these files)

---

## 6. Overall Success Criteria

- [ ] Project builds with Swift 6 compiler, zero warnings in changed files
- [ ] No `queue.sync` calls remain in `AnalyticsCollectionManager.swift`
- [ ] No `[self]` capture lists remain in `AnalyticsCollectionManager.swift`
- [ ] `ISO8601DateFormatter` allocated exactly once (static) in `LogItem.swift`
- [ ] `updateLogs()` is `async`, all SwiftUI call sites use `Task { await ... }`
- [ ] README contains no false actor claims; fire-and-forget write/clear methods shown without `await`
- [ ] `Collar.podspec` and `Package.swift` both declare version `2.0.0`
- [ ] PR review comments from kjaklinovic marked as resolved
