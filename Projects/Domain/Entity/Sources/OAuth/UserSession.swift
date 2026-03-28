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
  public var travelStationLat: Double?
  public var travelStationLng: Double?
  public var remainingMinutes: Int
  public var selectedExploreSpotID: String
  public var selectedExplorePlaceID: String
  public var explorePlacesFetchedAt: Date?

  public init(
    name: String = "",
    email: String = "",
    provider: SocialType = .apple,
    authCode: String = "",
    mapType: ExternalMapType = .appleMap,
    travelID: String = "",
    travelStationName: String = "",
    travelStationLat: Double? = nil,
    travelStationLng: Double? = nil,
    remainingMinutes: Int = 0,
    selectedExploreSpotID: String = "",
    selectedExplorePlaceID: String = "",
    explorePlacesFetchedAt: Date? = nil
  ) {
    self.name = name
    self.email = email
    self.provider = provider
    self.authCode = authCode
    self.mapType = mapType
    self.travelID = travelID
    self.travelStationName = travelStationName
    self.travelStationLat = travelStationLat
    self.travelStationLng = travelStationLng
    self.remainingMinutes = remainingMinutes
    self.selectedExploreSpotID = selectedExploreSpotID
    self.selectedExplorePlaceID = selectedExplorePlaceID
    self.explorePlacesFetchedAt = explorePlacesFetchedAt
  }
}

public extension UserSession {
  static let empty = UserSession()
}
