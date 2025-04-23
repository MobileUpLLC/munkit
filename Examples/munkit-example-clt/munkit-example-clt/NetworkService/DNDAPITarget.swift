//
//  DNDAPITarget.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

enum DNDAPITarget {
    case classesWithAuth
    case classesWithoutAuth
}

extension DNDAPITarget: MUNAPITarget {
    var parameters: [String: Any] { getParameters() }
    var isAccessTokenRequired: Bool { getIsAccessTokenRequired() }
    var isRefreshTokenRequest: Bool { getIsRefreshTokenRequest() }
    var baseURL: URL { getBaseURL() }
    var path: String { getPath() }
    var method: Moya.Method { getMethod() }
    var task: Moya.Task { getTask() }
    var headers: [String: String]? { getHeaders() }
    var authorizationType: Moya.AuthorizationType? { getAuthorizationType() }

    private func getParameters() -> [String: Any] {
        switch self {
        case .classesWithAuth, .classesWithoutAuth:
            return [:]
        }
    }

    private func getIsAccessTokenRequired() -> Bool {
        switch self {
        case .classesWithAuth:
            return true
        case .classesWithoutAuth:
            return false
        }
    }

    private func getIsRefreshTokenRequest() -> Bool {
        switch self {
        case .classesWithAuth, .classesWithoutAuth:
            return false
        }
    }

    private func getBaseURL() -> URL {
        switch self {
        case .classesWithAuth, .classesWithoutAuth:
            return URL(string: "https://www.dnd5eapi.co")!
        }
    }

    private func getPath() -> String {
        switch self {
        case .classesWithAuth, .classesWithoutAuth:
            return "/api/2014/classes"
        }
    }

    private func getMethod() -> Moya.Method {
        switch self {
        case .classesWithAuth, .classesWithoutAuth:
            return .get
        }
    }

    private func getTask() -> Moya.Task {
        switch self {
        case .classesWithAuth, .classesWithoutAuth:
            return .requestPlain
        }
    }

    private func getHeaders() -> [String: String]? {
        switch self {
        case .classesWithAuth, .classesWithoutAuth:
            return [:]
        }
    }

    private func getAuthorizationType() -> Moya.AuthorizationType? {
        switch self {
        case .classesWithAuth:
            return .bearer
        case .classesWithoutAuth:
            return nil
        }
    }
}
