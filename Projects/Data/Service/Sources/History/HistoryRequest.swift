//
//  HistoryRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//


import Foundation

public struct MyHistoryRequest: Encodable {
  public let page: Int
  public let size: Int
  public let sort: String

  public init(
    page: Int,
    size: Int,
    sort: String
  ) {
    self.page = page
    self.size = size
    self.sort = sort
  }
}

public struct StartJourneyRequest: Encodable {
  public let stationId: Int
  public let placeId: Int
  public let trainDepartureTime: String
  public let lat: Double
  public let lng: Double

  public init(
    stationId: Int,
    placeId: Int,
    trainDepartureTime: String,
    lat: Double,
    lng: Double
  ) {
    self.stationId = stationId
    self.placeId = placeId
    self.trainDepartureTime = trainDepartureTime
    self.lat = lat
    self.lng = lng
  }

  // Date를 받아서 ISO8601 형식으로 변환하는 편의 이니셜라이저
  public init(
    stationId: Int,
    placeId: Int,
    trainDepartureTime: Date,
    lat: Double,
    lng: Double
  ) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.timeZone = TimeZone.current

    self.stationId = stationId
    self.placeId = placeId
    self.trainDepartureTime = formatter.string(from: trainDepartureTime)
    self.lat = lat
    self.lng = lng
  }
}

public struct EndJourneyRequest: Encodable {
  public let journeyId: Int
  public let isCompleted: Bool

  public init(journeyId: Int, isCompleted: Bool = true) {
    self.journeyId = journeyId
    self.isCompleted = isCompleted
  }
}

// MARK: - Response DTOs

public struct ApiResponse<T: Codable>: Codable {
  public let code: Int
  public let message: String
  public let data: T

  public init(code: Int, message: String, data: T) {
    self.code = code
    self.message = message
    self.data = data
  }
}

public struct StartJourneyResponseDTO: Codable {
  public let visitingHistoryId: Int
  public let userId: String
  public let stationId: Int
  public let stationName: String
  public let stationAddress: String
  public let placeId: Int
  public let placeName: String
  public let placeCategory: String
  public let placeAddress: String
  public let startTime: String
  public let endTime: String?
  public let trainDepartureTime: String
  public let totalDurationMinutes: Int
  public let isInProgress: Bool
  public let isSuccess: Bool
  public let createdAt: String

  public init(
    visitingHistoryId: Int,
    userId: String,
    stationId: Int,
    stationName: String,
    stationAddress: String,
    placeId: Int,
    placeName: String,
    placeCategory: String,
    placeAddress: String,
    startTime: String,
    endTime: String? = nil,
    trainDepartureTime: String,
    totalDurationMinutes: Int,
    isInProgress: Bool,
    isSuccess: Bool,
    createdAt: String
  ) {
    self.visitingHistoryId = visitingHistoryId
    self.userId = userId
    self.stationId = stationId
    self.stationName = stationName
    self.stationAddress = stationAddress
    self.placeId = placeId
    self.placeName = placeName
    self.placeCategory = placeCategory
    self.placeAddress = placeAddress
    self.startTime = startTime
    self.endTime = endTime
    self.trainDepartureTime = trainDepartureTime
    self.totalDurationMinutes = totalDurationMinutes
    self.isInProgress = isInProgress
    self.isSuccess = isSuccess
    self.createdAt = createdAt
  }
}

