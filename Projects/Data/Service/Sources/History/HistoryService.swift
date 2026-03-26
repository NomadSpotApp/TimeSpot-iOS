//
//  HistoryService.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum HistoryService {
  case myHistory(body: MyHistoryRequest)
}


extension HistoryService: BaseTargetType {
  public typealias Domain = TimeSpotDomain

  public var domain: TimeSpotDomain {
    return .history
  }

  public var urlPath: String {
    switch self {
      case .myHistory:
        return HistoryAPI.myHistory.description
    }
  }

  public var error: [Int : NetworkError]? {
    return nil
  }

  public var method: Moya.Method {
    switch self {
      case .myHistory:
        return .get
    }
  }

  public var parameters: [String : Any]? {
    switch self {
      case .myHistory(let body):
        return body.toDictionary
    }
  }

  public var headers: [String : String]? {
    switch self {
      default:
        return APIHeader.baseHeader
    }
  }
}
