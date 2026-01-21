@testable import FlipperDevicesInc_MultiTransportConnectivityLayer_TestTask
import Foundation
import XCTest

private actor DeviceTransportSpy: AnyDeviceTransport {
    private let stream: AsyncStream<ConnectionState>
    private let continuation: AsyncStream<ConnectionState>.Continuation
    
    let isAvailable = true
    private(set) var connectCallCount = Int.zero
    private(set) var disconnectCallCount = Int.zero
    private(set) var sentRequests = [DeviceRequest]()
    private(set) var sendHandler: ((DeviceRequest) async throws -> Sendable)?

    nonisolated var connectionStateStream: AsyncStream<ConnectionState> {
        stream
    }
    
    init() {
        let stream = AsyncStream<ConnectionState>.makeStream()
        self.stream = stream.stream
        self.continuation = stream.continuation
    }

    func connect() async throws {
        connectCallCount += 1
        continuation.yield(.connected)
    }

    func disconnect() async throws {
        disconnectCallCount += 1
        continuation.yield(.disconnected)
    }

    func send<T: Decodable & Sendable>(_ request: DeviceRequest) async throws -> T {
        sentRequests.append(request)
        guard let handler = sendHandler else { throw NSError.create("sendHandler not set") }

        let result = try await handler(request)
        guard let typed = result as? T else { throw NSError.create("Unexpected response type") }

        return typed
    }
    
    func stubSend(_ handler: @escaping (DeviceRequest) async throws -> Any) {
        sendHandler = handler
    }
}

final class DeviceManagerTests: XCTestCase {
    func test_connect_triggersTransportToConnect() async throws {
        let (sut, transport) = makeSUT()

        try await sut.connect()
        
        let count = await transport.connectCallCount
        XCTAssertEqual(count, 1)
    }

    func test_disconnect_triggersTransportToDisconnect() async throws {
        let (sut, transport) = makeSUT()

        try await sut.disconnect()

        let count = await transport.disconnectCallCount
        XCTAssertEqual(count, 1)
    }

    func test_connectionStateStream_receivesConnectStateWhenConnected() async {
        let (sut, transport) = makeSUT()
        let exp = expectation(description: "received state")
        Task {
            for await state in sut.connectionStateStream {
                XCTAssertEqual(state, .connected)
                exp.fulfill()
                break
            }
        }

        try? await transport.connect()
        
        await fulfillment(of: [exp], timeout: 1)
    }

    func test_deviceInfo_sendsAndReceivesCorrectRequestAndResponse() async throws {
        let (sut, transport) = makeSUT()
        let expectedInfo = DeviceInfo.ble
        await transport.stubSend { request in
            XCTAssertEqual(request.endpoint, DeviceRequestEndpoint.deviceInfo)
            XCTAssertEqual(request.method, .get)
            return expectedInfo
        }

        let receivedInfo = try await sut.deviceInfo()
        
        let count = await transport.sentRequests.count
        XCTAssertEqual(receivedInfo, expectedInfo)
        XCTAssertEqual(count, 1)
    }

    func test_wifiNetworks_sendsAndReceivesCorrectRequestAndResponse() async throws {
        let (sut, transport) = makeSUT()
        let expectedNetworks = [WiFiNetwork.guest]
        await transport.stubSend { request in
            XCTAssertEqual(request.endpoint, DeviceRequestEndpoint.wifiNetworks)
            XCTAssertEqual(request.method, .get)
            return expectedNetworks
        }

        let result = try await sut.wifiNetworks()

        XCTAssertEqual(result, expectedNetworks)
    }

    func test_connectToWiFi_sendsAndReceivesCorrectRequestAndResponse() async throws {
        let (sut, transport) = makeSUT()
        await transport.stubSend { request in
            XCTAssertEqual(request.endpoint, DeviceRequestEndpoint.wifiConnect)
            XCTAssertEqual(request.method, .post)
            XCTAssertNotNil(request.body)

            let body = try XCTUnwrap(request.body)
            let decoded = try JSONDecoder().decode(WiFiConnectionRequest.self, from: body)
            XCTAssertEqual(decoded.ssid, "TestWiFi")
            XCTAssertEqual(decoded.password, "12345678")

            return Data()
        }

        try await sut.connectToWiFi(ssid: "TestWiFi", password: "12345678")

        let count = await transport.sentRequests.count
        XCTAssertEqual(count, 1)
    }
    
    func test_transportFailure_propagatesError() async {
        let (sut, transport) = makeSUT()
        let expectedError = NSError.anyError
        await transport.stubSend { _ in throw expectedError }

        do {
            _ = try await sut.deviceInfo()
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
}

private extension DeviceManagerTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: DeviceManager, transport: DeviceTransportSpy) {
        let transport = DeviceTransportSpy()
        let sut = DeviceManager(deviceTransport: transport)
        trackForMemoryLeaks(transport)
        trackForMemoryLeaks(sut)
        return (sut, transport)
    }
}
