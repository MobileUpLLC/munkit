import MUNKit

final class TokenProvider: MUNKTokenProvider {
    let accessToken: String? = nil

    func refreshToken() async throws -> String {
        ""
    }
}
