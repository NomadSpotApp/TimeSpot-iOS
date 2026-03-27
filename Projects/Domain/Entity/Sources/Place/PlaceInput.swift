//
//  PlaceInput.swift
//  Service
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation

public struct PlaceInput {
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

public struct PlaceSearchInput: Equatable {
  public let userLat: Double
  public let userLon: Double
  public let stationId: Int
  public let remainingMinutes: Int
  public let keyword: String?
  public let category: String?
  public let sortBy: String
  public let markerLat: Double?
  public let markerLon: Double?
  public let page: Int
  public let size: Int

  public init(
    userLat: Double,
    userLon: Double,
    stationId: Int,
    remainingMinutes: Int,
    keyword: String? = nil,
    category: String? = nil,
    sortBy: String = "MARKER_NEAREST",
    markerLat: Double? = nil,
    markerLon: Double? = nil,
    page: Int = 1,
    size: Int = 10
  ) {
    self.userLat = userLat
    self.userLon = userLon
    self.stationId = stationId
    self.remainingMinutes = remainingMinutes
    self.keyword = keyword
    self.category = category
    self.sortBy = sortBy
    self.markerLat = markerLat
    self.markerLon = markerLon
    self.page = page
    self.size = size
  }
}
