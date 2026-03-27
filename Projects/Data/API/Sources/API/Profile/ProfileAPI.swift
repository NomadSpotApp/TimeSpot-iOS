//
//  ProfileAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation

public enum ProfileAPI: String, CaseIterable {
  case user
  case editUser
  case fetchNotification
  case editNotification

  public var description : String {
    switch self {
      case .user:
        return ""
      case .editUser:
        return ""
      case .fetchNotification:
        return "/notification-settings"

      case .editNotification:
        return "/notification-settings"
    }
  }
}
