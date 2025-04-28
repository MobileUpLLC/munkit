//
//  DNDAPITarget.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

public enum DNDAPITarget {
    case classes
}

extension DNDAPITarget: MUNAPITarget {
    public var parameters: [String: Any] { getParameters() }
    public var isAccessTokenRequired: Bool { getIsAccessTokenRequired() }
    public var isRefreshTokenRequest: Bool { getIsRefreshTokenRequest() }
    public var baseURL: URL { getBaseURL() }
    public var path: String { getPath() }
    public var method: Moya.Method { getMethod() }
    public var task: Moya.Task { getTask() }
    public var headers: [String: String]? { getHeaders() }
    public var authorizationType: Moya.AuthorizationType? { getAuthorizationType() }
    public var mockFileName: String? { nil }
    public var isMockEnabled: Bool { false }

    private func getParameters() -> [String: Any] {
        switch self {
        case .classes:
            return [:]
        }
    }

    private func getIsAccessTokenRequired() -> Bool {
        switch self {
        case .classes:
            return false
        }
    }

    private func getIsRefreshTokenRequest() -> Bool {
        switch self {
        case .classes:
            return false
        }
    }

    private func getBaseURL() -> URL {
        switch self {
        case .classes:
            return URL(string: "https://www.dnd5eapi.co")!
        }
    }

    private func getPath() -> String {
        switch self {
        case .classes:
            return "/api/2014/classes"
        }
    }

    private func getMethod() -> Moya.Method {
        switch self {
        case .classes:
            return .get
        }
    }

    private func getTask() -> Moya.Task {
        switch self {
        case .classes:
            return .requestPlain
        }
    }

    private func getHeaders() -> [String: String]? {
        switch self {
        case .classes:
            return [:]
        }
    }

    private func getAuthorizationType() -> Moya.AuthorizationType? {
        switch self {
        case .classes:
            return nil
        }
    }
}
