//
//  HistoryEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct HistoryEntity: Equatable, Hashable {
  public let items: [HistoryItemEntity]
  public let totalElements: Int
  public let totalPages: Int
  public let size: Int
  public let page: Int
  public let isFirstPage: Bool
  public let isLastPage: Bool

  public init(
    items: [HistoryItemEntity],
    totalElements: Int,
    totalPages: Int,
    size: Int,
    page: Int,
    isFirstPage: Bool,
    isLastPage: Bool
  ) {
    self.items = items
    self.totalElements = totalElements
    self.totalPages = totalPages
    self.size = size
    self.page = page
    self.isFirstPage = isFirstPage
    self.isLastPage = isLastPage
  }
}

public extension HistoryEntity {
  var hasNextPage: Bool {
    !isLastPage && page < totalPages
  }

  var nextPage: Int? {
    hasNextPage ? page + 1 : nil
  }
}

public struct HistoryItemEntity: Equatable, Hashable, Identifiable {
  public let id: Int
  public let stationID: Int
  public let stationName: String
  public let placeID: Int
  public let placeName: String
  public let placeCategory: String
  public let startTime: String
  public let endTime: String?
  public let trainDepartureTime: String
  public let totalDurationMinutes: Int
  public let isInProgress: Bool
  public let isSuccess: Bool
  public let createdAt: String

  public init(
    id: Int,
    stationID: Int,
    stationName: String,
    placeID: Int,
    placeName: String,
    placeCategory: String,
    startTime: String,
    endTime: String?,
    trainDepartureTime: String,
    totalDurationMinutes: Int,
    isInProgress: Bool,
    isSuccess: Bool,
    createdAt: String
  ) {
    self.id = id
    self.stationID = stationID
    self.stationName = stationName
    self.placeID = placeID
    self.placeName = placeName
    self.placeCategory = placeCategory
    self.startTime = startTime
    self.endTime = endTime
    self.trainDepartureTime = trainDepartureTime
    self.totalDurationMinutes = totalDurationMinutes
    self.isInProgress = isInProgress
    self.isSuccess = isSuccess
    self.createdAt = createdAt
  }
}

// MARK: - Journey Entity

public struct JourneyEntity: Equatable, Hashable, Identifiable {
  public let id: Int // visitingHistoryId
  public let userId: String
  public let stationId: Int
  public let stationName: String
  public let stationAddress: String
  public let placeId: Int
  public let placeName: String
  public let placeCategory: String
  public let placeAddress: String
  public let startTime: Date
  public let endTime: Date?
  public let trainDepartureTime: Date
  public let totalDurationMinutes: Int
  public let isInProgress: Bool
  public let isSuccess: Bool
  public let createdAt: Date

  public init(
    id: Int,
    userId: String,
    stationId: Int,
    stationName: String,
    stationAddress: String,
    placeId: Int,
    placeName: String,
    placeCategory: String,
    placeAddress: String,
    startTime: Date,
    endTime: Date? = nil,
    trainDepartureTime: Date,
    totalDurationMinutes: Int,
    isInProgress: Bool,
    isSuccess: Bool,
    createdAt: Date
  ) {
    self.id = id
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
