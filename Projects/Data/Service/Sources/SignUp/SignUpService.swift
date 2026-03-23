//
//  SignUpService.swift
//  Service
//
//  Created by Wonji Suh  on 3/23/26.
//


import Foundation

import API
import Foundations

import AsyncMoya

public enum SignUpService{
  case signUp(body: SignUpRequestDTO)
}


extension SignUpService: BaseTargetType {
  public typealias Domain = TimeSpotDomain

  public var domain: TimeSpotDomain {
    switch self {
      case .signUp:
        return .auth
    }
  }

  public var urlPath: String {
    switch self {
      case .signUp:
        return SignUpAPI.signUp.description

    }
  }

  public var method: Moya.Method {
    switch self {
      case .signUp:
        return .post
    }
  }

  public var error: [Int : AsyncMoya.NetworkError]? {
    return  nil
  }

  public var parameters: [String : Any]? {
    switch self {
      case .signUp(let body):
        return body.toDictionary
    }
  }
}
