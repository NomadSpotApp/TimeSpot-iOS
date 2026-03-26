//
//  TimeSpotDomain.swift
//  API
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

import AsyncMoya

public enum TimeSpotDomain {
  case auth
  case place
  case profile
  case history
}

extension TimeSpotDomain: DomainType {
  public var baseURLString: String {
    return BaseAPI.base.apiDescription
  }

  public var url: String {
    switch self {
    case .auth:
      return "api/v1/auth"
      case .place:
        return "api/v1/place"
    case .profile:
      return "api/v1/users"
      case .history:
        return "api/v1/histories"
    }
  }
}
