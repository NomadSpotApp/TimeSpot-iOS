//
//  AuthService.swift
//  Service
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation
import Entity

import API
import Foundations

import AsyncMoya

public enum AuthService {
  case login(body: OAuthLoginRequest)
  case refresh(refreshToken: String)
  case logout

}


extension AuthService: BaseTargetType {
  public typealias Domain = TimeSpotDomain

  public var domain: TimeSpotDomain {
    switch self {
      case .login, .refresh, .logout:
        return .auth
    }
  }

  public var urlPath: String {
    switch self {
      case .login:
        return AuthAPI.login.description
      case .refresh:
        return AuthAPI.refresh.description
      case .logout:
        return AuthAPI.logout.description
    }
  }

  public var error: [Int : NetworkError]? {
    return nil
  }

  public var method: Moya.Method {
    switch self {
      case .login, .refresh, .logout:
        return .post
    }
  }

  public var parameters: [String : Any]? {
    switch self {
      case .login(let body):
        return body.toDictionary
      case .refresh(let refreshToken):
        return refreshToken.toDictionary(key: "refreshToken")
      case .logout:
        return nil
    }
  }

  public var headers: [String : String]? {
    switch self {
      case .logout:
        return APIHeader.baseHeader
      default:
        return APIHeader.notAccessTokenHeader
    }
  }

}
