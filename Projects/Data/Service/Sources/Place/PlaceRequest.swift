//
//  PlaceRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/27/26.
//


import Foundation

public struct PlaceRequest: Encodable {
  public let userLat: Double
  public let userLon: Double
  public let mapLat: Double
  public let mapLon: Double
  public let stationId: Int
  public let remainingMinutes: Int

  public init(
    userLat: Double,
    userLon: Double,
    mapLat: Double,
    mapLon: Double,
    stationId: Int,
    remainingMinutes: Int
  ) {
    self.userLat = userLat
    self.userLon = userLon
    self.mapLat = mapLat
    self.mapLon = mapLon
    self.stationId = stationId
    self.remainingMinutes = remainingMinutes
  }
}

public struct PlaceSearchRequest: Encodable {
  public let userLat: Double
  public let userLon: Double
  public let stationId: Int
  public let remainingMinutes: Int
  public let keyword: String?
  public let category: String?
  public let sortBy: String
  public let mapLat: Double?
  public let mapLon: Double?
  public let pageable: PageableRequest

  public init(
    userLat: Double,
    userLon: Double,
    stationId: Int,
    remainingMinutes: Int,
    keyword: String? = nil,
    category: String? = nil,
    sortBy: String = "STATION_NEAREST",
    mapLat: Double? = nil,
    mapLon: Double? = nil,
    pageable: PageableRequest = .init()
  ) {
    self.userLat = userLat
    self.userLon = userLon
    self.stationId = stationId
    self.remainingMinutes = remainingMinutes
    self.keyword = keyword
    self.category = category
    self.sortBy = sortBy
    self.mapLat = mapLat
    self.mapLon = mapLon
    self.pageable = pageable
  }
}

public struct PageableRequest: Encodable, Equatable {
  public let page: Int
  public let size: Int

  public init(
    page: Int = 0,
    size: Int = 10
  ) {
    self.page = page
    self.size = size
  }
}

public struct PlaceDetailRequest: Encodable {
  let placeId: Int
  let stationId: Int
  let userLat: Double
  let userLon: Double
  let remainingMinutes: Int

  public init(
    placeId: Int,
    stationId: Int,
    userLat: Double,
    userLon: Double,
    remainingMinutes: Int
  ) {
    self.placeId = placeId
    self.stationId = stationId
    self.userLat = userLat
    self.userLon = userLon
    self.remainingMinutes = remainingMinutes
  }
}
