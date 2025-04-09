import MUNKit

final class AuthRepository: MUNKTokenProvider {
    let accessToken: String? = nil

    func refreshToken() async throws -> String {
        ""
    }
}
