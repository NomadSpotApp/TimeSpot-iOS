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
