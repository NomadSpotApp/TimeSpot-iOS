//
//  NaverDirectionService.swift
//  Service
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

import AsyncMoya

public enum NaverDirectionService {
  case driving(start: String, goal: String, option: String)
  case walking(start: String, goal: String)
}

extension NaverDirectionService: TargetType {

  public var baseURL: URL {
    return URL(string: "https://maps.apigw.ntruss.com")!
  }

  public var path: String {
    return "/map-direction-15/v1/driving"
  }

  public var method: Moya.Method {
    return .get
  }

  public var task: Moya.Task {
    switch self {
    case .driving(let start, let goal, let option):
      return .requestParameters(
        parameters: [
          "start": start,
          "goal": goal,
          "option": option
        ],
        encoding: URLEncoding.queryString
      )

    case .walking(let start, let goal):
      return .requestParameters(
        parameters: [
          "start": start,
          "goal": goal
        ],
        encoding: URLEncoding.queryString
      )
    }
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