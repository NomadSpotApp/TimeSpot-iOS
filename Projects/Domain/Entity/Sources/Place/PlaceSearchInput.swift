//
//  PlaceSearchInput.swift
//  Entity
//
//  Created by Wonji Suh  on 3/29/26.
//

import Foundation


public struct PlaceSearchInput: Equatable {
  public let userLat: Double
  public let userLon: Double
  public let stationId: Int
  public let remainingMinutes: Int
  public let keyword: String?
  public let category: String?
  public let mapLat: Double?
  public let mapLon: Double?
  public let page: Int
  public let size: Int
  public let sort: String

  public init(
    userLat: Double,
    userLon: Double,
    stationId: Int,
    remainingMinutes: Int,
    keyword: String? = nil,
    category: String? = nil,
    mapLat: Double? = nil,
    mapLon: Double? = nil,
    page: Int = 1,
    size: Int = 50,
    sort: String = "distanceFromStation,ASC"
  ) {
    self.userLat = userLat
    self.userLon = userLon
    self.stationId = stationId
    self.remainingMinutes = remainingMinutes
    self.keyword = keyword
    self.category = category
    self.mapLat = mapLat
    self.mapLon = mapLon
    self.page = page
    self.size = size
    self.sort = sort
  }
}
