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
  case editProfile(body: ProfileRequest)
  case fetchNotification
  case editNotification(body: EditNotificationRequest)
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

      case .editProfile:
        return ProfileAPI.editUser.description

      case .fetchNotification:
        return ProfileAPI.fetchNotification.description

      case .editNotification:
        return ProfileAPI.editNotification.description
    }
  }

  public var error: [Int : NetworkError]? {
    return nil
  }

  public var method: Moya.Method {
    switch self {
      case .fetchProfile, .fetchNotification:
        return .get

      case .editProfile:
        return .post

      case .editNotification:
        return .put
    }
  }

  public var parameters: [String : Any]? {
    switch self {
      case .fetchProfile, .fetchNotification:
        return nil

      case .editProfile(let body):
        return body.toDictionary

      case .editNotification(let body):
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
