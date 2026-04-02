//
//  NaverDirectionService.swift
//  Service
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

import API
import AsyncMoya
import Foundations

// MARK: - Direction Service
public enum NaverDirectionService {
  case walking(start: String, goal: String, option: String)    // Directions 15 - 실시간 경로
}

extension NaverDirectionService: BaseTargetType {
  public typealias Domain = NaverDirectionDomain

  // MARK: - API Credentials (Foundations 모듈에서 관리)

  public var domain: NaverDirectionDomain {
    return .walking     // map-direction-15/v1 (실시간 경로)
  }

  public var baseURL: URL {
    guard let url = URL(string: domain.baseURLString) else {
      fatalError("🚨 [NaverAPI] Invalid base URL: \(domain.baseURLString)")
    }
    return url
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
    return NaverAPICredentials.shared.headers
  }
}
