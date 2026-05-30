# Flipper Devices Inc. | Multi-Transport Connectivity Layer for IoT Device | Senior iOS Engineer Take-Home Assignment

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#task-description">Task Description</a></li>
    <li><a href="#project-documentation">Project Documentation</a></li>
  </ol>
</details>

# Task Description
Build a robust connectivity layer that demonstrates your expertise in Swift Concurrency, protocol-oriented design, state management, and testing. This assignment is inspired by real production challenges in IoT device communication.


## The Assignment
Build a multi-transport connectivity system that can communicate with an IoT device through BLE, WiFi, or USB. The system must handle transport switching, connection lifecycle, and device operations seamlessly.

## Key Features
1. Multi-Transport Support: Connect via BLE (Bluetooth Low Energy), WiFi (HTTP), or USB (mock)
2. Transport Abstraction: Unified API regardless of underlying transport
3. Automatic Failover: Attempt alternate transports when primary fails
4. Connection Lifecycle: Handle discovery, connection, disconnection, and errors
5. Device Operations: Execute commands and queries through the connected transport


## Requirements
### 1. Transport Layer Architecture
#### Must Have:
- Protocol-based transport abstraction
- Three concrete implementations: BLETransport, WiFiTransport, USBTransport
- Unified API for device communication
- Each transport handles its own connection state

#### Transport Protocol Requirements:
```swift
protocol DeviceTransport: Sendable {
    var connectionState: AsyncStream<ConnectionState> { get }
    func connect() async throws
    func disconnect() async throws
    func send<T: Decodable>(_ request: DeviceRequest) async throws -> T
    var isAvailable: Bool { get async }
}
```

#### Connection States:
- Disconnected
- Discovering
- Connecting
- Connected
- Failed(Error)

### 2. Transport Orchestrator
#### Must Have:
Build an orchestrator that:
- Manages multiple transport instances
- Attempts connection in priority order (BLE → WiFi → USB)
- Automatically falls back to next transport on failure
- Cancels in-flight operations when switching transports
- Maintains single active transport at a time
- Provides unified connection state to UI layer

### 3. Device Operations
#### Must Have:
Device commands that work across all transports:
1. Get Device Info
   - Fetch device name, firmware version, battery level
3. Configure WiFi
   - Scan for WiFi networks (BLE or USB only)
   - Connect device to WiFi network
   - Disconnect from WiFi
5. Update Firmware
   - Upload firmware file in chunks
   - Track upload progress
   - Handle upload failures/retries

#### Request/Response Model:
```swift
struct DeviceRequest: Sendable {
    let endpoint: String
    let method: HTTPMethod
    let body: Data?
}

struct DeviceInfo: Codable {
    let name: String
    let firmwareVersion: String
    let batteryLevel: Int
}

struct WiFiNetwork: Codable {
    let ssid: String
    let signalStrength: Int
    let securityType: SecurityType
}
```

### 4. State Management
#### Must Have:
- Connection state per transport
- Global orchestrator state
- Operation in-progress states
- Error states with recovery options
- Transport availability changes (e.g., Bluetooth turned off)

#### State Machine Requirements:
- Single source of truth
- Thread-safe state updates
- State observation via AsyncStream
- Proper cleanup on state transitions

### 5. Testing
#### You Must Provide:
1. Mock Transport Implementations
   - MockBLETransport
   - MockWiFiTransport
   - MockUSBTransport
   - Configurable delays, failures, state changes
3. Unit Tests
   - Transport lifecycle (connect, disconnect, reconnect)
   - Orchestrator failover logic
   - Concurrent request handling
   - Cancellation behavior
   - Error recovery


## Technical Requirements
#### Architecture:
- Swift 6.0 with strict concurrency
- Actor-based concurrency for state management
- AsyncStream for state observation
- Protocol-oriented design
- No third-party dependencies (pure Swift/Foundation)

#### Documentation:
- Architecture diagram (simple markdown diagram)
- Protocol documentation
- Key design decisions explained
- Test strategy overview


## Provided Specifications
### BLE Transport Specs
#### Connection Flow:
1. Scan for peripherals with service UUID: `0000180A-0000-1000-8000-00805F9B34FB`
2. Connect to peripheral
3. Discover UART service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
4. Discover RX/TX characteristics
5. Enable notifications on RX characteristic
6. Send HTTP-style requests via TX characteristic (max 237 bytes per packet)
7. Receive responses via RX notifications (chunked, assemble by Content-Length)

*Note: You don't need to implement actual CoreBluetooth code. Mock the BLE layer.*

### WiFi Transport Specs
#### Connection:
- Device has IP address (e.g., 192.168.1.100)
- Standard HTTP REST API
- Base URL: `http://192.168.1.100:8080`

#### Endpoints:
- `GET /api/device/info` → DeviceInfo
- `GET /api/wifi/networks` → [WiFiNetwork]
- `POST /api/wifi/connect` → Body: `{ssid, password}`
- `POST /api/wifi/disconnect`
- `POST /api/firmware/upload` → Multipart upload

### USB Transport Specs
#### Connection:
- Mock USB connection (no actual USB implementation needed).
- Same HTTP-style request/response protocol as BLE.
- No packet size limits.
- Synchronous responses (no chunking).


## Bonus Points (Optional)
#### Only if you finish early:
1. Connection Health Monitor
   - Periodic ping/heartbeat
   - Automatic reconnection on connection loss
   - Connection quality metrics
3. Request Queue
   - Queue requests during reconnection
   - Replay failed requests
   - Request priority handling
5. Advanced Testing
   - Stress test with 100+ rapid requests
   - Memory leak detection
   - Race condition testing
7. Metrics & Logging
   - Connection time tracking
   - Request latency metrics
   - Structured logging


## Tips
- Start with protocol definitions and mock implementations
- Test early and often
- Focus on the orchestrator failover logic – it's the hardest part
- Don't overcomplicate – clean, working code beats over-engineered solutions
- Use actors for state management – they're perfect for this
- Remember: the goal is to show your thinking, not to build production-ready code

#### Good luck! We're excited to see your solution.

# Project Documentation
#### Hi, dear reviewers! 👋


## Dependency Diagram
The Dependency Diagram can be found in the Dependency Diagram folder (drawio/png).
![Dependency Diagram](Dependency%20Diagram/Dependency%20Diagram.png)


## Protocol/Class documentation
### AnyDeviceTransportConnectionStateManager
A protocol for storing and updating the connection state.
It is used by BLETransport, USBTransport, WiFiTransport to eliminate duplicated logic.

- DeviceTransportConnectionStateManager an implementation of AnyDeviceTransportConnectionStateManager. 
It has pure logic with no side effects

- DeviceTransportConnectionStateManagerWithSynchronization a decorator for AnyDeviceTransportConnectionStateManager 
that synchronizes updates of the connection status.
Example: connect() -> status is connecting -> disconnect() -> connectTask gets cancelled -> status gets disconnected

### AnyDeviceTransport
A protocol for transport logic.

- BLETransport an implementation of AnyDeviceTransport.
Mock BLE layer.

- USBTransport an implementation of AnyDeviceTransport.
Mock USB layer.

- WiFiTransport an implementation of AnyDeviceTransport.
Mock WiFi layer.

- DeviceTransportWithSendingErrorWhenNotConnected a decorator for AnyDeviceTransport that fails initiated send requests 
when the connection state is not connected.
Example: state is not connected -> try sendRequest() -> sendRequestTask immediately fails

- DeviceTransportWithSendingCancellationWhenNotConnected a decorator for AnyDeviceTransport 
that cancels pending send requests when the connection state gets disconnected/failed.
Example: sendRequest() -> sending is in progress -> status gets disconnected -> sendRequestTask gets cancelled

- DeviceTransportOrchestrator a decorator for AnyDeviceTransport that manages a fallback AnyDeviceTransport
when the primary connects with an error.
Example: state is not connected -> try primary.connect() fails -> try fallback.connect() 

### AnyDeviceManager
A protocol that execute device operations.

- DeviceManager an implementation of AnyDeviceManager. Uses AnyDeviceTransport to work.


## Key design decisions explained
- iOS 18 for Mutex from the Synchronization framework. It's possible to create a custom implementation for lower versions, 
but I decided to avoid it. Actors are great to protect shared mutable state from data races in concurrent code. 
But they can't be used everywhere. It's possible to ignore swift concurrency restrictions using `nonisolated(unsafe) var` 
or `@unchecked Sendable`, but Mutex is just better and easy to use.

- Decorators are used to add side effects without changing the pure logic in implementations.
They are compact, easy to test and can be easily turned off if necessary.

- Composite pattern is used to treat individual objects and compositions of objects uniformly.
It allows to build tree structures where modules can work with a single object or a group of objects through the same interface, without needing to know which is which.

- Protocol-Oriented Programming (POP) - each implementation conforms to a specific protocol.
It's used in order to inject protocol dependencies that can be easily mocked.


## Commit History
https://github.com/sharojke/FlipperDevicesInc-MultiTransportConnectivityLayer-TestTask/commits/main/
