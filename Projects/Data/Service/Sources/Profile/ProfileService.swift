//
//  ProfileService.swift
//  Service
//
//  Created by Wonji Suh  on 3/25/26.
//


import Foundation

import API
import Foundations

import AsyncMoya


public enum ProfileService {
  case fetchProfile
}


extension ProfileService: BaseTargetType {
  public typealias Domain = TimeSpotDomain

  public var domain: TimeSpotDomain {
    return .profile
  }

  public var urlPath: String {
    switch self {
      case .fetchProfile:
        return ProfileAPI.user.description
    }
  }

  public var error: [Int : NetworkError]? {
    return nil
  }

  public var method: Moya.Method {
    switch self {
      case .fetchProfile:
        return .get
    }
  }

  public var parameters: [String : Any]? {
    switch self {
      case .fetchProfile:
        return nil
    }
  }

  public var headers: [String : String]? {
    switch self {
      default:
        return APIHeader.baseHeader
    }
  }
}
