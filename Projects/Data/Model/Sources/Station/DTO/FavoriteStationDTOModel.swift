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
}

public struct FavoriteStationItemResponseDTO: Decodable, Equatable {
  public let favoriteID: Int
  public let stationID: Int
  public let stationName: String
  public let visitCount: Int
  public let createdAt: String

  enum CodingKeys: String, CodingKey {
    case favoriteID = "favoriteId"
    case stationID = "stationId"
    case stationName
    case visitCount
    case createdAt
  }

  public init(
    favoriteID: Int,
    stationID: Int,
    stationName: String,
    visitCount: Int,
    createdAt: String
  ) {
    self.favoriteID = favoriteID
    self.stationID = stationID
    self.stationName = stationName
    self.visitCount = visitCount
    self.createdAt = createdAt
  }
}
