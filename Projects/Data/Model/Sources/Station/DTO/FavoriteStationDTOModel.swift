//
//  FavoriteStationDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public typealias FavoriteStationDTOModel = BaseResponseDTO<FavoriteStationPageResponseDTO>

public struct FavoriteStationPageResponseDTO: Decodable, Equatable {
  public let content: [FavoriteStationItemResponseDTO]
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
    content: [FavoriteStationItemResponseDTO],
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
    let content = try container.decode([FavoriteStationItemResponseDTO].self, forKey: .content)
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

public struct FavoriteStationItemResponseDTO: Decodable, Equatable {
  public let favoriteID: Int
  public let stationID: Int
  public let stationName: String
  public let visitCount: Int
  public let totalVisitMinutes: Int
  public let createdAt: String

  enum CodingKeys: String, CodingKey {
    case favoriteID = "favoriteId"
    case stationID = "stationId"
    case stationName
    case visitCount
    case totalVisitMinutes
    case createdAt
  }

  public init(
    favoriteID: Int,
    stationID: Int,
    stationName: String,
    visitCount: Int,
    totalVisitMinutes: Int,
    createdAt: String
  ) {
    self.favoriteID = favoriteID
    self.stationID = stationID
    self.stationName = stationName
    self.visitCount = visitCount
    self.totalVisitMinutes = totalVisitMinutes
    self.createdAt = createdAt
  }
}
