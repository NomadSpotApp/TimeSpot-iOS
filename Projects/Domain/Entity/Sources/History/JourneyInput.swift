//
//  JourneyInput.swift
//  Entity
//
//  Created by Wonji Suh  on 4/1/26.
//

import Foundation

// MARK: - Journey Input

public struct StartJourneyInput: Equatable, Hashable {
  public let stationId: Int
  public let placeId: Int
  public let trainDepartureTime: Date
  public let lat: Double
  public let lng: Double

  public init(
    stationId: Int,
    placeId: Int,
    trainDepartureTime: Date,
    lat: Double,
    lng: Double
  ) {
    self.stationId = stationId
    self.placeId = placeId
    self.trainDepartureTime = trainDepartureTime
    self.lat = lat
    self.lng = lng
  }
}