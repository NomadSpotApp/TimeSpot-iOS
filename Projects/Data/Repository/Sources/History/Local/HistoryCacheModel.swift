//
//  HistoryCacheModel.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

@Model
final class HistoryListCacheEntity {
  /// sort + size 조합 캐시 키 (page=1만 캐시)
  @Attribute(.unique) var cacheKey: String
  var sortRawValue: String
  var cachedAt: Date

  // Page metadata
  var totalElements: Int
  var totalPages: Int
  var size: Int
  var page: Int
  var isFirstPage: Bool
  var isLastPage: Bool

  @Relationship(deleteRule: .cascade)
  var items: [HistoryItemCacheEntity]

  init(
    cacheKey: String,
    sortRawValue: String,
    cachedAt: Date,
    totalElements: Int,
    totalPages: Int,
    size: Int,
    page: Int,
    isFirstPage: Bool,
    isLastPage: Bool,
    items: [HistoryItemCacheEntity] = []
  ) {
    self.cacheKey = cacheKey
    self.sortRawValue = sortRawValue
    self.cachedAt = cachedAt
    self.totalElements = totalElements
    self.totalPages = totalPages
    self.size = size
    self.page = page
    self.isFirstPage = isFirstPage
    self.isLastPage = isLastPage
    self.items = items
  }

  // 만료: 당일
  var isExpired: Bool {
    !Calendar.current.isDate(cachedAt, inSameDayAs: Date())
  }
}

@Model
final class HistoryItemCacheEntity {
  var historyID: Int
  var stationID: Int
  var stationName: String
  var placeID: String
  var placeName: String
  var placeCategory: String
  var startTime: String
  var endTime: String?
  var trainDepartureTime: String
  var totalDurationMinutes: Int
  var isInProgress: Bool
  var isSuccess: Bool
  var createdAt: String
  var orderIndex: Int

  init(
    historyID: Int,
    stationID: Int,
    stationName: String,
    placeID: String,
    placeName: String,
    placeCategory: String,
    startTime: String,
    endTime: String?,
    trainDepartureTime: String,
    totalDurationMinutes: Int,
    isInProgress: Bool,
    isSuccess: Bool,
    createdAt: String,
    orderIndex: Int
  ) {
    self.historyID = historyID
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
    self.orderIndex = orderIndex
  }

  func toDomain() -> HistoryItemEntity {
    HistoryItemEntity(
      id: historyID,
      stationID: stationID,
      stationName: stationName,
      placeID: placeID,
      placeName: placeName,
      placeCategory: placeCategory,
      startTime: startTime,
      endTime: endTime,
      trainDepartureTime: trainDepartureTime,
      totalDurationMinutes: totalDurationMinutes,
      isInProgress: isInProgress,
      isSuccess: isSuccess,
      createdAt: createdAt
    )
  }
}

extension HistoryItemEntity {
  func toCacheModel(orderIndex: Int) -> HistoryItemCacheEntity {
    HistoryItemCacheEntity(
      historyID: id,
      stationID: stationID,
      stationName: stationName,
      placeID: placeID,
      placeName: placeName,
      placeCategory: placeCategory,
      startTime: startTime,
      endTime: endTime,
      trainDepartureTime: trainDepartureTime,
      totalDurationMinutes: totalDurationMinutes,
      isInProgress: isInProgress,
      isSuccess: isSuccess,
      createdAt: createdAt,
      orderIndex: orderIndex
    )
  }
}

extension HistoryEntity {
  func toCacheModel(cacheKey: String, sort: TravelHistorySort) -> HistoryListCacheEntity {
    let cache = HistoryListCacheEntity(
      cacheKey: cacheKey,
      sortRawValue: sort.rawValue,
      cachedAt: Date(),
      totalElements: totalElements,
      totalPages: totalPages,
      size: size,
      page: page,
      isFirstPage: isFirstPage,
      isLastPage: isLastPage
    )
    cache.items = items.enumerated().map { index, item in
      item.toCacheModel(orderIndex: index)
    }
    return cache
  }
}

extension HistoryListCacheEntity {
  func toDomain() -> HistoryEntity {
    let sortedItems = items.sorted { $0.orderIndex < $1.orderIndex }
    return HistoryEntity(
      items: sortedItems.map { $0.toDomain() },
      totalElements: totalElements,
      totalPages: totalPages,
      size: size,
      page: page,
      isFirstPage: isFirstPage,
      isLastPage: isLastPage
    )
  }
}

enum HistoryCacheKey {
  static func list(sort: TravelHistorySort, size: Int) -> String {
    "history|sort\(sort.rawValue)|sz\(size)|p1"
  }
}
