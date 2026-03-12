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

// MARK: - Base Target Type Protocol
public protocol BaseTargetType: TargetType {
  associatedtype Domain

  var domain: Domain { get }
  var urlPath: String { get }
  var error: [Int: AsyncMoya.NetworkError]? { get }
  var parameters: [String: Any]? { get }
}

extension BaseTargetType {
  public var task: Moya.Task {
    if let parameters = parameters {
      return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
    } else {
      return .requestPlain
    }
  }
}

// MARK: - Direction API Endpoints
public enum DirectionAPI : String {
  case driving = "/map-direction-15/v1/driving"

  public var description: String {
    return self.rawValue
  }
}

// MARK: - Direction Service
public enum NaverDirectionService {
  case driving(start: String, goal: String, option: String)
  case walking(start: String, goal: String)
}

extension NaverDirectionService: BaseTargetType {
  public typealias Domain = BaseAPI

  public var domain: BaseAPI {
    return .naver
  }

  public var baseURL: URL {
    return URL(string: domain.apiDescription)!
  }

  public var path: String {
    return urlPath
  }

  public var urlPath: String {
    switch self {
    case .driving, .walking:
      return DirectionAPI.driving.description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? {
    return nil
  }

  public var parameters: [String: Any]? {
    switch self {
    case .driving(let start, let goal, let option):
      return [
        "start": start,
        "goal": goal,
        "option": option
      ]

    case .walking(let start, let goal):
      return [
        "start": start,
        "goal": goal
      ]
    }
  }

  public var method: Moya.Method {
    return .get
  }

  public var headers: [String: String]? {
    let clientId = "dt5ybexksb"
    let clientSecret = "8oQfeamg7HNsWOqHjO1MsCzjzx4gZy3RQeaoq76N"

    return [
      "X-NCP-APIGW-API-KEY-ID": clientId,
      "X-NCP-APIGW-API-KEY": clientSecret,
      "Content-Type": "application/json"
    ]
  }
}
