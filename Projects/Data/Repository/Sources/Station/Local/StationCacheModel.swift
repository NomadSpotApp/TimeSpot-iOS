//
//  StationCacheModel.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

enum StationCacheSection: String {
  case favorite
  case nearby
  case major
}

@Model
final class StationCacheEntity {
  @Attribute(.unique) var cacheKey: String
  var cachedAt: Date

  // Page metadata (major section)
  var totalElements: Int
  var totalPages: Int
  var size: Int
  var page: Int
  var numberOfElements: Int
  var isFirstPage: Bool
  var isLastPage: Bool
  var isEmpty: Bool

  @Relationship(deleteRule: .cascade)
  var items: [StationCacheItemEntity]

  init(
    cacheKey: String,
    cachedAt: Date,
    totalElements: Int,
    totalPages: Int,
    size: Int,
    page: Int,
    numberOfElements: Int,
    isFirstPage: Bool,
    isLastPage: Bool,
    isEmpty: Bool,
    items: [StationCacheItemEntity] = []
  ) {
    self.cacheKey = cacheKey
    self.cachedAt = cachedAt
    self.totalElements = totalElements
    self.totalPages = totalPages
    self.size = size
    self.page = page
    self.numberOfElements = numberOfElements
    self.isFirstPage = isFirstPage
    self.isLastPage = isLastPage
    self.isEmpty = isEmpty
    self.items = items
  }

  // 날짜가 변경되면 캐시 만료
  var isExpired: Bool {
    !Calendar.current.isDate(cachedAt, inSameDayAs: Date())
  }
}

@Model
final class StationCacheItemEntity {
  var sectionRawValue: String
  var favoriteID: Int?
  var stationID: Int
  var name: String
  var lines: [String]
  var lat: Double?
  var lng: Double?
  var orderIndex: Int

  init(
    sectionRawValue: String,
    favoriteID: Int?,
    stationID: Int,
    name: String,
    lines: [String],
    lat: Double?,
    lng: Double?,
    orderIndex: Int
  ) {
    self.sectionRawValue = sectionRawValue
    self.favoriteID = favoriteID
    self.stationID = stationID
    self.name = name
    self.lines = lines
    self.lat = lat
    self.lng = lng
    self.orderIndex = orderIndex
  }

  var section: StationCacheSection {
    StationCacheSection(rawValue: sectionRawValue) ?? .major
  }

  func toDomain() -> StationSummaryEntity {
    StationSummaryEntity(
      favoriteID: favoriteID,
      stationID: stationID,
      name: name,
      lines: lines,
      lat: lat,
      lng: lng
    )
  }
}

extension StationSummaryEntity {
  func toCacheModel(
    section: StationCacheSection,
    orderIndex: Int
  ) -> StationCacheItemEntity {
    StationCacheItemEntity(
      sectionRawValue: section.rawValue,
      favoriteID: favoriteID,
      stationID: stationID,
      name: name,
      lines: lines,
      lat: lat,
      lng: lng,
      orderIndex: orderIndex
    )
  }
}

extension StationListEntity {
  func toCacheModel(cacheKey: String) -> StationCacheEntity {
    let cache = StationCacheEntity(
      cacheKey: cacheKey,
      cachedAt: Date(),
      totalElements: stations.totalElements,
      totalPages: stations.totalPages,
      size: stations.size,
      page: stations.page,
      numberOfElements: stations.numberOfElements,
      isFirstPage: stations.isFirstPage,
      isLastPage: stations.isLastPage,
      isEmpty: stations.isEmpty
    )

    let favoriteItems = favoriteStations.enumerated().map { index, item in
      item.toCacheModel(section: .favorite, orderIndex: index)
    }
    let nearbyItems = nearbyStations.enumerated().map { index, item in
      item.toCacheModel(section: .nearby, orderIndex: index)
    }
    let majorItems = stations.content.enumerated().map { index, item in
      item.toCacheModel(section: .major, orderIndex: index)
    }

    cache.items = favoriteItems + nearbyItems + majorItems
    return cache
  }
}

extension StationCacheEntity {
  func toDomain() -> StationListEntity {
    let sorted = items.sorted { $0.orderIndex < $1.orderIndex }
    let favorites = sorted
      .filter { $0.section == .favorite }
      .map { $0.toDomain() }
    let nearby = sorted
      .filter { $0.section == .nearby }
      .map { $0.toDomain() }
    let major = sorted
      .filter { $0.section == .major }
      .map { $0.toDomain() }

    return StationListEntity(
      favoriteStations: favorites,
      nearbyStations: nearby,
      stations: StationPageEntity(
        content: major,
        totalElements: totalElements,
        totalPages: totalPages,
        size: size,
        page: page,
        numberOfElements: numberOfElements,
        isFirstPage: isFirstPage,
        isLastPage: isLastPage,
        isEmpty: isEmpty
      )
    )
  }
}
