@testable import FlipperDevicesInc_MultiTransportConnectivityLayer_TestTask
import Foundation
import XCTest

final class DeviceTransportConnectionStateManagerTests: XCTestCase {
    func test_connect_setConnectedStateOnSuccess() async throws {
        let sut = makeSUT()
        let connectExp = expectation(description: "Connect closure called")
        let successfulConnect: @Sendable () async throws -> Void = { connectExp.fulfill() }
        
        try await sut.connect(successfulConnect)
        let state = await sut.connectionState
        
        XCTAssertEqual(state, .connected)
        await fulfillment(of: [connectExp], timeout: 1)
    }
    
    func test_connect_setFailedStateOnFailure() async throws {
        let sut = makeSUT()
        let expectedError = NSError.anyError
        let notSuccessfulConnect: @Sendable () async throws -> Void = { throw expectedError }
                
        do {
            try await sut.connect(notSuccessfulConnect)
            XCTFail("Connect should throw")
        } catch {
            if case .failed(let receivedError as NSError) = await sut.connectionState {
                XCTAssertEqual(receivedError, expectedError)
            } else {
                XCTFail("State should be failed")
            }
        }
    }
 
    func test_disconnect_setDisconnectedStateOnSuccess() async throws {
        let sut = makeSUT()
        
        let successfulConnect: @Sendable () async throws -> Void = {}
        try await sut.connect(successfulConnect)
        
        let successfulDisconnect: @Sendable () async throws -> Void = {}
        try await sut.disconnect(successfulDisconnect)
        
        let state = await sut.connectionState
        XCTAssertEqual(state, .disconnected)
    }

    func test_failConnection_setsFailedStateWithGivenError() async throws {
        let sut = makeSUT()
        let expectedError = NSError.anyError
        
        await sut.failConnection(with: expectedError)
        let state = await sut.connectionState
        
        if case .failed(let receivedError as NSError) = state {
            XCTAssertEqual(expectedError, receivedError)
        } else {
            XCTFail("State should be failed")
        }
    }

    func test_connect_doesNotChangeTheStateOnSuccessfullyConnectingTwice() async throws {
        let sut = makeSUT()
        let successfulConnect: @Sendable () async throws -> Void = {}
        
        try await sut.connect(successfulConnect)
        let stateBefore = await sut.connectionState
        
        try await sut.connect(successfulConnect)
        let stateAfter = await sut.connectionState
        
        XCTAssertEqual(stateBefore, stateAfter)
    }
    
    func test_disconnect_doesNotChangeTheStateOnSuccessfullyDisconnectingTwice() async throws {
        let sut = makeSUT()
        let successfulDisconnect: @Sendable () async throws -> Void = {}
        
        try await sut.disconnect(successfulDisconnect)
        let stateBefore = await sut.connectionState
        
        try await sut.disconnect(successfulDisconnect)
        let stateAfter = await sut.connectionState
        
        XCTAssertEqual(stateBefore, stateAfter)
    }
}

private extension DeviceTransportConnectionStateManagerTests {
    func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> DeviceTransportConnectionStateManager {
        let sut = DeviceTransportConnectionStateManager()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
