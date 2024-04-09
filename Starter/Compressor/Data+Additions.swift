import Foundation

extension Data {
  var prettySize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .binary
    return formatter.string(fromByteCount: Int64(count))
  }
}
