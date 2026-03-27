//
//  PlaceEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/27/26.
//

import  Foundation

public struct PlaceEntity: Equatable {
  public let stationId: String
  public let name: String
  public let address: String
  public let  category: ExploreCategory
  public let lat, lon: Double
  public let stayableMinutes: Int

  public init(
    stationId: String,
    name: String,
    address: String,
    category: ExploreCategory,
    lat: Double,
    lon: Double,
    stayableMinutes: Int
  ) {
    self.stationId = stationId
    self.name = name
    self.address = address
    self.category = category
    self.lat = lat
    self.lon = lon
    self.stayableMinutes = stayableMinutes
  }
}
