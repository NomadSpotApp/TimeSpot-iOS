//
//  SignUpAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

public enum SignUpAPI: String , CaseIterable {
  case signUp

  public var description: String {
    switch self {
      case .signUp:
        return "/signup"
    }
  }

}

