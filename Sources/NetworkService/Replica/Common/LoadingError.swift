/// Представляет собой ошибку, возникшую во время сетевого запроса.
public struct LoadingError: Sendable {
    public let reason: LoadingReason
    public let error: Error
}
