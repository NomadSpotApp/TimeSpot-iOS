//
//  PlaceDetailInput.swift
//  Entity
//
//  Created by Wonji Suh  on 3/29/26.
//

import Foundation

public struct PlaceDetailInput: Equatable {
  public let placeId: Int
  public let stationId: Int
  public let userLat: Double
  public let userLon: Double
  public let remainingMinutes: Int

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
