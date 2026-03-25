//
//  ProfileAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation

public enum ProfileAPI: String, CaseIterable {
  case user

  public var description : String {
    switch self {
      case .user:
        return ""
    }
  }
}
