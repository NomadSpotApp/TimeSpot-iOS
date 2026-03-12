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
  case walking(start: String, goal: String, option: String)    // Directions 15 - 실시간 경로
}

extension NaverDirectionService: BaseTargetType {
  public typealias Domain = NaverDirectionDomain

  public var domain: NaverDirectionDomain {
    return .walking     // map-direction-15/v1 (실시간 경로)
  }

  public var baseURL: URL {
    return URL(string: domain.baseURLString)!
  }

  public var path: String {
    return urlPath
  }

  public var urlPath: String {
    return "\(domain.url)/driving"
  }

  public var error: [Int: AsyncMoya.NetworkError]? {
    return nil
  }

  public var parameters: [String: Any]? {
    switch self {
    case .walking(let start, let goal, let option):
      var params: [String: Any] = [:]
      params.merge(start.toDictionary(key: "start")) { _, new in new }
      params.merge(goal.toDictionary(key: "goal")) { _, new in new }
      params["option"] = option
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
