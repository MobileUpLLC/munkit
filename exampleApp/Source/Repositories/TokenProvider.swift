import MUNKit

final class TokenProvider: MUNKTokenProvider {
    func refreshToken() async throws {}
    
    let accessToken: String? = nil
}
