//
//  NaverDirectionService.swift
//  Service
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

import API
import AsyncMoya

// MARK: - Direction Service
public enum NaverDirectionService {
  case driving(start: String, goal: String, option: String)
  case walking(start: String, goal: String)
}

extension NaverDirectionService: BaseTargetType {
  public typealias Domain = NaverDirectionDomain

  public var domain: NaverDirectionDomain {
    switch self {
    case .driving:
      return .direction
    case .walking:
      return .walking
    }
  }

  public var baseURL: URL {
    return URL(string: domain.baseURLString)!
  }

  public var path: String {
    return urlPath
  }

  public var urlPath: String {
    switch self {
    case .driving:
      return "\(domain.url)/driving"
    case .walking:
      return "\(domain.url)/walking"
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? {
    return nil
  }

  public var parameters: [String: Any]? {
    switch self {
    case .driving(let start, let goal, let option):
      var params: [String: Any] = [:]
      params.merge(start.toDictionary(key: "start")) { _, new in new }
      params.merge(goal.toDictionary(key: "goal")) { _, new in new }
      params.merge(option.toDictionary(key: "option")) { _, new in new }
      return params

    case .walking(let start, let goal):
      var params: [String: Any] = [:]
      params.merge(start.toDictionary(key: "start")) { _, new in new }
      params.merge(goal.toDictionary(key: "goal")) { _, new in new }
      return params
    }
  }

  public var method: Moya.Method {
    return .get
  }

  public var headers: [String: String]? {
    let clientId = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientId") as? String ?? ""
    let clientSecret = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientSecret") as? String ?? ""

    return [
      "X-NCP-APIGW-API-KEY-ID": clientId,
      "X-NCP-APIGW-API-KEY": clientSecret,
      "Content-Type": "application/json"
    ]
  }
}
