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
  public var isGuest: Bool
  public var travelID: String
  public var travelStationName: String
  public var travelStationLat: Double?
  public var travelStationLng: Double?
  public var remainingMinutes: Int
  public var departureTime: Date?
  public var selectedExploreSpotID: String
  public var selectedExplorePlaceID: String
  public var explorePlacesFetchedAt: Date?

  // MARK: - Route 관련 위치 정보
  public var routeStartLat: Double?  // 현재 위치 (출발지) 위도
  public var routeStartLng: Double?  // 현재 위치 (출발지) 경도
  public var routeDestinationLat: Double?  // 목적지 위도
  public var routeDestinationLng: Double?  // 목적지 경도
  public var routeDestinationName: String  // 목적지 이름

  // MARK: - 경로 정보
  public var routeDistance: Int  // 경로 거리 (미터)
  public var routeDuration: Int  // 경로 소요시간 (분)
  public var nearestStationName: String  // 가장 가까운 역 이름
  public var nearestStationLat: Double?  // 가장 가까운 역 위도
  public var nearestStationLng: Double?  // 가장 가까운 역 경도

  public init(
    name: String = "",
    email: String = "",
    provider: SocialType = .apple,
    authCode: String = "",
    mapType: ExternalMapType = .appleMap,
    isGuest: Bool = false,
    travelID: String = "",
    travelStationName: String = "",
    travelStationLat: Double? = nil,
    travelStationLng: Double? = nil,
    remainingMinutes: Int = 0,
    departureTime: Date? = nil,
    selectedExploreSpotID: String = "",
    selectedExplorePlaceID: String = "",
    explorePlacesFetchedAt: Date? = nil,
    routeStartLat: Double? = nil,
    routeStartLng: Double? = nil,
    routeDestinationLat: Double? = nil,
    routeDestinationLng: Double? = nil,
    routeDestinationName: String = "",
    routeDistance: Int = 0,
    routeDuration: Int = 0,
    nearestStationName: String = "",
    nearestStationLat: Double? = nil,
    nearestStationLng: Double? = nil
  ) {
    self.name = name
    self.email = email
    self.provider = provider
    self.authCode = authCode
    self.mapType = mapType
    self.isGuest = isGuest
    self.travelID = travelID
    self.travelStationName = travelStationName
    self.travelStationLat = travelStationLat
    self.travelStationLng = travelStationLng
    self.remainingMinutes = remainingMinutes
    self.departureTime = departureTime
    self.selectedExploreSpotID = selectedExploreSpotID
    self.selectedExplorePlaceID = selectedExplorePlaceID
    self.explorePlacesFetchedAt = explorePlacesFetchedAt
    self.routeStartLat = routeStartLat
    self.routeStartLng = routeStartLng
    self.routeDestinationLat = routeDestinationLat
    self.routeDestinationLng = routeDestinationLng
    self.routeDestinationName = routeDestinationName
    self.routeDistance = routeDistance
    self.routeDuration = routeDuration
    self.nearestStationName = nearestStationName
    self.nearestStationLat = nearestStationLat
    self.nearestStationLng = nearestStationLng
  }
}

public extension UserSession {
  static let empty = UserSession()
}
