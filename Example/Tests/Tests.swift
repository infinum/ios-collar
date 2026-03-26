import XCTest
import Collar

class Tests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        // Clear logs before each test
        await AnalyticsCollectionManager.shared.clearLogs()
    }
    
    override func tearDown() async throws {
        // Clear logs after each test
        await AnalyticsCollectionManager.shared.clearLogs()
        try await super.tearDown()
    }
    
    // MARK: - Basic Logging Tests
    
    func testLogEventWithParameters() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        // Log test event
        await manager.log(
            event: "test_event",
            parameters: [
                "user_id": .string("123"),
                "action": .string("tap")
            ]
        )
        
        // Verify log was added
        let logs = await manager.logs
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.name, "test_event")
        XCTAssertEqual(logs.first?.parameters?["user_id"], .string("123"))
        XCTAssertEqual(logs.first?.parameters?["action"], .string("tap"))
    }
    
    func testLogEventWithoutParameters() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        await manager.log(event: "simple_event", parameters: nil)
        
        let logs = await manager.logs
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.name, "simple_event")
        XCTAssertNil(logs.first?.parameters)
    }
    
    func testTrackScreenView() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        await manager.track(screenName: "HomeScreen", screenClass: "HomeViewController")
        
        let logs = await manager.logs
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.name, "HomeScreen")
        XCTAssertEqual(logs.first?.value, "HomeViewController")
        XCTAssertEqual(logs.first?.type, .screen)
    }
    
    func testSetUserProperty() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        await manager.setUserProperty("premium", forName: "subscription_type")
        
        let logs = await manager.logs
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.name, "subscription_type")
        XCTAssertEqual(logs.first?.value, "premium")
        XCTAssertEqual(logs.first?.type, .userProperty)
    }
    
    // MARK: - Log Management Tests
    
    func testClearAllLogs() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        // Add multiple logs
        await manager.log(event: "event1", parameters: nil)
        await manager.log(event: "event2", parameters: nil)
        await manager.log(event: "event3", parameters: nil)
        
        var logs = await manager.logs
        XCTAssertEqual(logs.count, 3)
        
        // Clear all logs
        await manager.clearLogs()
        
        logs = await manager.logs
        XCTAssertEqual(logs.count, 0)
    }
    
    func testClearSpecificLog() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        // Add multiple logs
        await manager.log(event: "event1", parameters: nil)
        await manager.log(event: "event2", parameters: nil)
        await manager.log(event: "event3", parameters: nil)
        
        // Get logs and remove middle one
        let logs = await manager.logs
        XCTAssertEqual(logs.count, 3)
        
        let middleLog = logs[1]
        await manager.clearLog(middleLog)
        
        // Verify correct log removed
        let remainingLogs = await manager.logs
        XCTAssertEqual(remainingLogs.count, 2)
        XCTAssertFalse(remainingLogs.contains(where: { $0.id == middleLog.id }))
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentLogging() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        // Launch 50 concurrent log operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    await manager.log(
                        event: "concurrent_event_\(i)",
                        parameters: ["index": .int(i)]
                    )
                }
            }
        }
        
        // Verify all logs were added
        let logs = await manager.logs
        XCTAssertEqual(logs.count, 50)
        
        // Verify no duplicates (actor serialization guarantee)
        let uniqueEvents = Set(logs.map { $0.name })
        XCTAssertEqual(uniqueEvents.count, 50)
    }
    
    func testConcurrentReadsAndWrites() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        let iterations = 20
        
        // Concurrent writes and reads
        await withTaskGroup(of: Void.self) { group in
            // Writer tasks
            for i in 0..<iterations {
                group.addTask {
                    await manager.log(event: "write_\(i)", parameters: nil)
                }
            }
            
            // Reader tasks (interleaved)
            for _ in 0..<iterations {
                group.addTask {
                    _ = await manager.logs
                }
            }
        }
        
        // Verify final count
        let finalLogs = await manager.logs
        XCTAssertEqual(finalLogs.count, iterations)
    }
    
    // MARK: - Notification Tests
    
    func testNotificationPostedOnLogUpdate() async throws {
        let expectation = XCTestExpectation(description: "Notification received")
        let manager = AnalyticsCollectionManager.shared
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AnalyticsCollectionManager.didUpdateLogs"),
            object: nil,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }
        
        await manager.log(event: "test", parameters: nil)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - LoggerJsonValue Tests
    
    func testLoggerJsonValueTypes() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        await manager.log(
            event: "mixed_types",
            parameters: [
                "string": .string("test"),
                "int": .int(42),
                "double": .double(3.14),
                "bool": .bool(true),
                "array": .array([.int(1), .int(2), .int(3)]),
                "object": .object(["key": .string("value")]),
                "null": .null
            ]
        )
        
        let logs = await manager.logs
        XCTAssertEqual(logs.count, 1)
        
        let params = logs.first?.parameters
        XCTAssertEqual(params?["string"], .string("test"))
        XCTAssertEqual(params?["int"], .int(42))
        XCTAssertEqual(params?["double"], .double(3.14))
        XCTAssertEqual(params?["bool"], .bool(true))
    }
    
    // MARK: - Performance Tests
    
    func testLoggingPerformance() async throws {
        let manager = AnalyticsCollectionManager.shared
        
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                // Clear logs before each measured iteration
                await manager.clearLogs()
                
                for i in 0..<100 {
                    await manager.log(event: "perf_event_\(i)", parameters: nil)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
