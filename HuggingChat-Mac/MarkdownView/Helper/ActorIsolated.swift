import Foundation

actor ActorIsolated<Value> {
    public var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
}
