//
//  JourneyEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 4/1/26.
//

import Foundation

public struct JourneyEntity: Equatable, Hashable, Identifiable {
  public let id: Int // visitingHistoryId
  public let stationId: Int
  public let stationName: String
  public let stationAddress: String
  public let placeId: String
  public let placeName: String
  public let placeCategory: String
  public let placeAddress: String
  public let placeLat: Double
  public let placeLng: Double
  public let startTime: Date
  public let endTime: Date?
  public let trainDepartureTime: Date
  public let totalDurationMinutes: Int
  public let isInProgress: Bool
  public let isSuccess: Bool
  public let createdAt: Date
  public let startLat: Double?
  public let startLng: Double?

  public init(
    id: Int,
    stationId: Int,
    stationName: String,
    stationAddress: String,
    placeId: String,
    placeName: String,
    placeCategory: String,
    placeAddress: String,
    placeLat: Double,
    placeLng: Double,
    startTime: Date,
    endTime: Date? = nil,
    trainDepartureTime: Date,
    totalDurationMinutes: Int,
    isInProgress: Bool,
    isSuccess: Bool,
    createdAt: Date,
    startLat: Double? = nil,
    startLng: Double? = nil
  ) {
    self.id = id
    self.stationId = stationId
    self.stationName = stationName
    self.stationAddress = stationAddress
    self.placeId = placeId
    self.placeName = placeName
    self.placeCategory = placeCategory
    self.placeAddress = placeAddress
    self.placeLat = placeLat
    self.placeLng = placeLng
    self.startTime = startTime
    self.endTime = endTime
    self.trainDepartureTime = trainDepartureTime
    self.totalDurationMinutes = totalDurationMinutes
    self.isInProgress = isInProgress
    self.isSuccess = isSuccess
    self.createdAt = createdAt
    self.startLat = startLat
    self.startLng = startLng
  }
}

