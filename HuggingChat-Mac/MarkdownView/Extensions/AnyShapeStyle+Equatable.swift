import SwiftUI

extension AnyShapeStyle: @retroactive Equatable {
    public static func == (lhs: AnyShapeStyle, rhs: AnyShapeStyle) -> Bool {
        let oldBuffer = withUnsafeBytes(of: lhs) { $0 }
        let newBuffer = withUnsafeBytes(of: rhs) { $0 }
        
        if let oldPointer = oldBuffer.baseAddress,
           let newPointer = newBuffer.baseAddress {
            let oldBytes = Data(bytes: oldPointer, count: oldBuffer.count)
            let newBytes = Data(bytes: newPointer, count: newBuffer.count)
            // Compare the hash value of two data.
            // When `style` changes, the data changes.
            if oldBytes.hashValue == newBytes.hashValue {
                return true
            }
        }
        return false
    }
}
