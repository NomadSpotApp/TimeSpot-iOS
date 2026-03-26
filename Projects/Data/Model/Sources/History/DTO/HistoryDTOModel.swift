//
//  HistoryDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public typealias HistoryDTOModel = BaseResponseDTO<HistoryPageResponseDTO>

public struct HistoryPageResponseDTO: Decodable, Equatable {
  public let content: [HistoryItemResponseDTO]
  public let totalElements: Int
  public let totalPages: Int
  public let size: Int
  public let number: Int
  public let first: Bool
  public let last: Bool

  enum CodingKeys: String, CodingKey {
    case content
    case totalElements
    case totalPages
    case size
    case number
    case first
    case last
    case hasNext
  }

  public init(
    content: [HistoryItemResponseDTO],
    totalElements: Int,
    totalPages: Int,
    size: Int,
    number: Int,
    first: Bool,
    last: Bool
  ) {
    self.content = content
    self.totalElements = totalElements
    self.totalPages = totalPages
    self.size = size
    self.number = number
    self.first = first
    self.last = last
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let content = try container.decode([HistoryItemResponseDTO].self, forKey: .content)
    let totalElements = try container.decode(Int.self, forKey: .totalElements)
    let totalPages = try container.decode(Int.self, forKey: .totalPages)
    let size = try container.decode(Int.self, forKey: .size)
    let number = try container.decode(Int.self, forKey: .number)

    let hasNext = try container.decodeIfPresent(Bool.self, forKey: .hasNext) ?? false
    let first = try container.decodeIfPresent(Bool.self, forKey: .first) ?? (number == 0)
    let last = try container.decodeIfPresent(Bool.self, forKey: .last) ?? !hasNext

    self.init(
      content: content,
      totalElements: totalElements,
      totalPages: totalPages,
      size: size,
      number: number,
      first: first,
      last: last
    )
  }
}

public struct HistoryItemResponseDTO: Decodable, Equatable {
  public let visitingHistoryID: Int
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

  enum CodingKeys: String, CodingKey {
    case visitingHistoryID = "visitingHistoryId"
    case stationID = "stationId"
    case stationName
    case placeID = "placeId"
    case placeName
    case placeCategory
    case startTime
    case endTime
    case trainDepartureTime
    case totalDurationMinutes
    case isInProgress
    case isSuccess
    case createdAt
  }

  public init(
    visitingHistoryID: Int,
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
    self.visitingHistoryID = visitingHistoryID
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
