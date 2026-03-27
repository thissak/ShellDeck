import Foundation

protocol SessionProtocol: AnyObject {
    func connect() async throws
    func disconnect()
    var state: ConnectionState { get }
    var onStateChange: ((ConnectionState) -> Void)? { get set }
    var onData: ((Data) -> Void)? { get set }
    func write(_ data: Data) throws
    func resizePTY(cols: Int, rows: Int) throws
}
