//
//  StationListEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct StationListEntity: Equatable, Hashable {
  public let favoriteStations: [StationSummaryEntity]
  public let nearbyStations: [StationSummaryEntity]
  public let stations: StationPageEntity

  public init(
    favoriteStations: [StationSummaryEntity],
    nearbyStations: [StationSummaryEntity],
    stations: StationPageEntity
  ) {
    self.favoriteStations = favoriteStations
    self.nearbyStations = nearbyStations
    self.stations = stations
  }
}

public struct StationSummaryEntity: Equatable, Hashable, Identifiable {
  public let favoriteID: Int?
  public let stationID: Int
  public let name: String
  public let lines: [String]
  public let lat: Double?
  public let lng: Double?

  public var id: Int { stationID }

  public init(
    favoriteID: Int? = nil,
    stationID: Int,
    name: String,
    lines: [String],
    lat: Double? = nil,
    lng: Double? = nil
  ) {
    self.favoriteID = favoriteID
    self.stationID = stationID
    self.name = name
    self.lines = lines
    self.lat = lat
    self.lng = lng
  }
}

public struct StationPageEntity: Equatable, Hashable {
  public let content: [StationSummaryEntity]
  public let totalElements: Int
  public let totalPages: Int
  public let size: Int
  public let page: Int
  public let numberOfElements: Int
  public let isFirstPage: Bool
  public let isLastPage: Bool
  public let isEmpty: Bool

  public init(
    content: [StationSummaryEntity],
    totalElements: Int,
    totalPages: Int,
    size: Int,
    page: Int,
    numberOfElements: Int,
    isFirstPage: Bool,
    isLastPage: Bool,
    isEmpty: Bool
  ) {
    self.content = content
    self.totalElements = totalElements
    self.totalPages = totalPages
    self.size = size
    self.page = page
    self.numberOfElements = numberOfElements
    self.isFirstPage = isFirstPage
    self.isLastPage = isLastPage
    self.isEmpty = isEmpty
  }
}

public extension StationPageEntity {
  var hasNextPage: Bool {
    !isLastPage && page < totalPages
  }

  var nextPage: Int? {
    hasNextPage ? page + 1 : nil
  }
}
