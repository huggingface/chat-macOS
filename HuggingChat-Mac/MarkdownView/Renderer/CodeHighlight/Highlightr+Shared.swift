#if canImport(Highlightr)
@preconcurrency import Highlightr
#endif

#if canImport(Highlightr)
extension Highlightr {
    static let shared: ActorIsolated<Highlightr?> = ActorIsolated(Highlightr())
}
#endif
