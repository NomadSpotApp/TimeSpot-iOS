//
//  FavoriteStationEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct FavoriteStationEntity: Equatable, Hashable {
  public let items: [FavoriteStationItemEntity]
  public let totalElements: Int
  public let totalPages: Int
  public let size: Int
  public let page: Int
  public let isFirstPage: Bool
  public let isLastPage: Bool

  public init(
    items: [FavoriteStationItemEntity],
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

public extension FavoriteStationEntity {
  var hasNextPage: Bool {
    !isLastPage && page < totalPages
  }

  var nextPage: Int? {
    hasNextPage ? page + 1 : nil
  }
}

public struct FavoriteStationItemEntity: Equatable, Hashable, Identifiable {
  public let favoriteID: Int
  public let stationID: Int
  public let stationName: String
  public let visitCount: Int
  public let createdAt: String

  public var id: Int { favoriteID }

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
