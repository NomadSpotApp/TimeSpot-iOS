//
//  UserSession.swift
//  Entity
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

public struct UserSession: Equatable, Hashable {
  public var name: String
  public var email: String
  public var provider: SocialType
  public var authCode: String
  public var mapType: ExternalMapType
  public var travelID: String
  public var travelStationName: String

  public init(
    name: String = "",
    email: String = "",
    provider: SocialType = .apple,
    authCode: String = "",
    mapType: ExternalMapType = .appleMap,
    travelID: String = "",
    travelStationName: String = ""
  ) {
    self.name = name
    self.email = email
    self.provider = provider
    self.authCode = authCode
    self.mapType = mapType
    self.travelID = travelID
    self.travelStationName = travelStationName
  }
}

public extension UserSession {
  static let empty = UserSession()
}
