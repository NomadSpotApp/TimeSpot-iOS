//
//  PlaceRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/27/26.
//


import Foundation

// 기존 PlaceRequest 제거 - FetchPlaceRequest 사용

public struct FetchPlaceRequest: Encodable {
  public let stationId: Int
  public let userLat: Double
  public let userLon: Double
  public let remainingMinutes: Int
  public let mapLat: Double?
  public let mapLon: Double?
  public let keyword: String?
  public let category: String?
  public let page: Int
  public let size: Int
  public let sort: String

  public init(
    stationId: Int,
    userLat: Double,
    userLon: Double,
    remainingMinutes: Int,
    mapLat: Double? = nil,
    mapLon: Double? = nil,
    keyword: String? = nil,
    category: String? = nil,
    page: Int = 1,
    size: Int = 50,
    sort: String = "distanceFromStation,ASC"
  ) {
    self.stationId = stationId
    self.userLat = userLat
    self.userLon = userLon
    self.remainingMinutes = remainingMinutes
    self.mapLat = mapLat
    self.mapLon = mapLon
    self.keyword = keyword
    self.category = category
    self.page = page
    self.size = size
    self.sort = sort
  }
}

public struct PlaceDetailRequest: Encodable {
  let stationId: Int
  let userLat: Double
  let userLon: Double
  let remainingMinutes: Int

  public init(
    stationId: Int,
    userLat: Double,
    userLon: Double,
    remainingMinutes: Int
  ) {
    self.stationId = stationId
    self.userLat = userLat
    self.userLon = userLon
    self.remainingMinutes = remainingMinutes
  }
}
