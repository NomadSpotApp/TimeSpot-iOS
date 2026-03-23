//
//  AuthAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

public enum AuthAPI: String, CaseIterable {
  case login
  case logout
  case refresh

  public var description: String {
    switch self {
      case .login:
        return "/login"
      case .logout:
        return "/logout"
      case .refresh:
        return "/refresh"
    }
  }
}
