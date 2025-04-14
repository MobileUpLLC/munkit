import munkit

final class TokenProvider: MUNAccessTokenProvider {
    func refreshToken() async throws {}
    
    let accessToken: String? = nil
}
