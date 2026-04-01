//
//  JourneyDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 4/1/26.
//

import Foundation

public typealias StartJourneyDTOModel = BaseResponseDTO<JourneyResponseDTO>
public typealias EndJourneyDTOModel = BaseResponseDTO<JourneyResponseDTO>

public struct JourneyResponseDTO: Decodable, Equatable {
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

  enum CodingKeys: String, CodingKey {
    case visitingHistoryId
    case userId
    case stationId
    case stationName
    case stationAddress
    case placeId
    case placeName
    case placeCategory
    case placeAddress
    case startTime
    case endTime
    case trainDepartureTime
    case totalDurationMinutes
    case isInProgress
    case isSuccess
    case createdAt
  }

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