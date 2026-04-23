//
//  PlaceCacheModel.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

// MARK: - List Cache (PlaceSearchPageEntity)

@Model
final class PlaceListCacheEntity {
  @Attribute(.unique) var cacheKey: String
  var cachedAt: Date

  // Page metadata
  var page: Int
  var size: Int
  var numberOfElements: Int
  var isFirstPage: Bool
  var isLastPage: Bool
  var isEmpty: Bool

  // Pageable metadata
  var pageableIsUnpaged: Bool
  var pageableIsPaged: Bool
  var pageableNumber: Int
  var pageableSize: Int
  var pageableOffset: Int

  // Sort metadata
  var sortIsUnsorted: Bool
  var sortIsSorted: Bool
  var sortIsEmpty: Bool

  @Relationship(deleteRule: .cascade)
  var items: [PlaceCacheItemEntity]

  init(
    cacheKey: String,
    cachedAt: Date,
    page: Int,
    size: Int,
    numberOfElements: Int,
    isFirstPage: Bool,
    isLastPage: Bool,
    isEmpty: Bool,
    pageableIsUnpaged: Bool,
    pageableIsPaged: Bool,
    pageableNumber: Int,
    pageableSize: Int,
    pageableOffset: Int,
    sortIsUnsorted: Bool,
    sortIsSorted: Bool,
    sortIsEmpty: Bool,
    items: [PlaceCacheItemEntity] = []
  ) {
    self.cacheKey = cacheKey
    self.cachedAt = cachedAt
    self.page = page
    self.size = size
    self.numberOfElements = numberOfElements
    self.isFirstPage = isFirstPage
    self.isLastPage = isLastPage
    self.isEmpty = isEmpty
    self.pageableIsUnpaged = pageableIsUnpaged
    self.pageableIsPaged = pageableIsPaged
    self.pageableNumber = pageableNumber
    self.pageableSize = pageableSize
    self.pageableOffset = pageableOffset
    self.sortIsUnsorted = sortIsUnsorted
    self.sortIsSorted = sortIsSorted
    self.sortIsEmpty = sortIsEmpty
    self.items = items
  }

  // 만료: 당일
  var isExpired: Bool {
    !Calendar.current.isDate(cachedAt, inSameDayAs: Date())
  }
}

@Model
final class PlaceCacheItemEntity {
  var placeId: Int
  var name: String
  var categoryRawValue: String
  var address: String
  var lat: Double
  var lon: Double
  var imageURL: String?
  var stayableMinutes: Int
  var isOpen: Bool
  var closingTime: String?
  var distanceFromUser: Double?
  var distanceFromStation: Double?
  var walkTimeFromStation: Int?
  var visitable: Bool
  var orderIndex: Int

  init(
    placeId: Int,
    name: String,
    categoryRawValue: String,
    address: String,
    lat: Double,
    lon: Double,
    imageURL: String?,
    stayableMinutes: Int,
    isOpen: Bool,
    closingTime: String?,
    distanceFromUser: Double?,
    distanceFromStation: Double?,
    walkTimeFromStation: Int?,
    visitable: Bool,
    orderIndex: Int
  ) {
    self.placeId = placeId
    self.name = name
    self.categoryRawValue = categoryRawValue
    self.address = address
    self.lat = lat
    self.lon = lon
    self.imageURL = imageURL
    self.stayableMinutes = stayableMinutes
    self.isOpen = isOpen
    self.closingTime = closingTime
    self.distanceFromUser = distanceFromUser
    self.distanceFromStation = distanceFromStation
    self.walkTimeFromStation = walkTimeFromStation
    self.visitable = visitable
    self.orderIndex = orderIndex
  }

  func toDomain() -> PlaceEntity {
    PlaceEntity(
      placeId: placeId,
      name: name,
      category: ExploreCategory(rawValue: categoryRawValue) ?? .all,
      lat: lat,
      lon: lon,
      address: address,
      imageURL: imageURL,
      stayableMinutes: stayableMinutes,
      isOpen: isOpen,
      closingTime: closingTime,
      distanceFromUser: distanceFromUser,
      distanceFromStation: distanceFromStation,
      walkTimeFromStation: walkTimeFromStation,
      visitable: visitable
    )
  }
}

// MARK: - Detail Cache (PlaceDetailEntity)

@Model
final class PlaceDetailCacheEntity {
  /// 위/경도 변경 감지용 복합 캐시 키 (placeId + quantized userLat/userLon)
  /// 사용자 위치가 ~100m 이상 이동하면 cache miss → walkTime 재요청
  @Attribute(.unique) var cacheKey: String
  var placeId: String
  var cachedAt: Date

  var name: String
  var category: String
  var address: String
  var latitude: Double
  var longitude: Double
  var distanceFromStation: Int
  var walkTimeFromStation: Int
  var stayableMinutes: Int
  var visitable: Bool
  var stationLatitude: Double
  var stationLongitude: Double
  var leaveTime: String
  var images: [String]
  var useTime: String?
  var spendTime: String?
  var useFee: String?
  var discountInfo: String?
  var accomCountCulture: String?
  var parkingCulture: String?
  var placeType: String

  init(
    cacheKey: String,
    placeId: String,
    cachedAt: Date,
    name: String,
    category: String,
    address: String,
    latitude: Double,
    longitude: Double,
    distanceFromStation: Int,
    walkTimeFromStation: Int,
    stayableMinutes: Int,
    visitable: Bool,
    stationLatitude: Double,
    stationLongitude: Double,
    leaveTime: String,
    images: [String],
    useTime: String?,
    spendTime: String?,
    useFee: String?,
    discountInfo: String?,
    accomCountCulture: String?,
    parkingCulture: String?,
    placeType: String
  ) {
    self.cacheKey = cacheKey
    self.placeId = placeId
    self.cachedAt = cachedAt
    self.name = name
    self.category = category
    self.address = address
    self.latitude = latitude
    self.longitude = longitude
    self.distanceFromStation = distanceFromStation
    self.walkTimeFromStation = walkTimeFromStation
    self.stayableMinutes = stayableMinutes
    self.visitable = visitable
    self.stationLatitude = stationLatitude
    self.stationLongitude = stationLongitude
    self.leaveTime = leaveTime
    self.images = images
    self.useTime = useTime
    self.spendTime = spendTime
    self.useFee = useFee
    self.discountInfo = discountInfo
    self.accomCountCulture = accomCountCulture
    self.parkingCulture = parkingCulture
    self.placeType = placeType
  }

  // 만료: 당일
  var isExpired: Bool {
    !Calendar.current.isDate(cachedAt, inSameDayAs: Date())
  }

  func toDomain() -> PlaceDetailEntity {
    PlaceDetailEntity(
      placeId: placeId,
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceFromStation: distanceFromStation,
      walkTimeFromStation: walkTimeFromStation,
      stayableMinutes: stayableMinutes,
      visitable: visitable,
      stationLatitude: stationLatitude,
      stationLongitude: stationLongitude,
      leaveTime: leaveTime,
      images: images,
      useTime: useTime,
      spendTime: spendTime,
      useFee: useFee,
      discountInfo: discountInfo,
      accomCountCulture: accomCountCulture,
      parkingCulture: parkingCulture,
      placeType: placeType
    )
  }
}

// MARK: - Mapping (Domain -> Cache)

extension PlaceEntity {
  func toCacheModel(orderIndex: Int) -> PlaceCacheItemEntity {
    PlaceCacheItemEntity(
      placeId: placeId,
      name: name,
      categoryRawValue: category.rawValue,
      address: address,
      lat: lat,
      lon: lon,
      imageURL: imageURL,
      stayableMinutes: stayableMinutes,
      isOpen: isOpen,
      closingTime: closingTime,
      distanceFromUser: distanceFromUser,
      distanceFromStation: distanceFromStation,
      walkTimeFromStation: walkTimeFromStation,
      visitable: visitable,
      orderIndex: orderIndex
    )
  }
}

extension PlaceSearchPageEntity {
  func toCacheModel(cacheKey: String) -> PlaceListCacheEntity {
    let cache = PlaceListCacheEntity(
      cacheKey: cacheKey,
      cachedAt: Date(),
      page: page,
      size: size,
      numberOfElements: numberOfElements,
      isFirstPage: isFirstPage,
      isLastPage: isLastPage,
      isEmpty: isEmpty,
      pageableIsUnpaged: pageable.isUnpaged,
      pageableIsPaged: pageable.isPaged,
      pageableNumber: pageable.pageNumber,
      pageableSize: pageable.pageSize,
      pageableOffset: pageable.offset,
      sortIsUnsorted: sort.isUnsorted,
      sortIsSorted: sort.isSorted,
      sortIsEmpty: sort.isEmpty
    )
    cache.items = content.enumerated().map { index, item in
      item.toCacheModel(orderIndex: index)
    }
    return cache
  }
}

extension PlaceListCacheEntity {
  func toDomain() -> PlaceSearchPageEntity {
    let sortedItems = items.sorted { $0.orderIndex < $1.orderIndex }
    return PlaceSearchPageEntity(
      pageable: PlacePageableEntity(
        isUnpaged: pageableIsUnpaged,
        isPaged: pageableIsPaged,
        pageNumber: pageableNumber,
        pageSize: pageableSize,
        offset: pageableOffset,
        sort: PlaceSortEntity(
          isUnsorted: sortIsUnsorted,
          isSorted: sortIsSorted,
          isEmpty: sortIsEmpty
        )
      ),
      isLastPage: isLastPage,
      numberOfElements: numberOfElements,
      isFirstPage: isFirstPage,
      size: size,
      content: sortedItems.map { $0.toDomain() },
      page: page,
      sort: PlaceSortEntity(
        isUnsorted: sortIsUnsorted,
        isSorted: sortIsSorted,
        isEmpty: sortIsEmpty
      ),
      isEmpty: isEmpty
    )
  }
}

extension PlaceDetailEntity {
  func toCacheModel(cacheKey: String) -> PlaceDetailCacheEntity {
    PlaceDetailCacheEntity(
      cacheKey: cacheKey,
      placeId: placeId,
      cachedAt: Date(),
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceFromStation: distanceFromStation,
      walkTimeFromStation: walkTimeFromStation,
      stayableMinutes: stayableMinutes,
      visitable: visitable,
      stationLatitude: stationLatitude,
      stationLongitude: stationLongitude,
      leaveTime: leaveTime,
      images: images,
      useTime: useTime,
      spendTime: spendTime,
      useFee: useFee,
      discountInfo: discountInfo,
      accomCountCulture: accomCountCulture,
      parkingCulture: parkingCulture,
      placeType: placeType
    )
  }
}

// MARK: - Cache Key Builder

enum PlaceCacheKey {
  /// 위/경도를 grid 단위로 quantize하여 메모리 절약 (~100m 정밀도)
  static func quantize(_ value: Double?, precision: Int = 3) -> String {
    guard let value else { return "_" }
    let multiplier = pow(10.0, Double(precision))
    let rounded = (value * multiplier).rounded() / multiplier
    return String(format: "%.\(precision)f", rounded)
  }

  static func list(input: PlaceSearchInput) -> String {
    let userLat = quantize(input.userLat, precision: 4)  // ~10m
    let userLon = quantize(input.userLon, precision: 4)
    let mapLat = quantize(input.mapLat, precision: 3)    // ~100m
    let mapLon = quantize(input.mapLon, precision: 3)
    let keyword = input.keyword?.isEmpty == false ? input.keyword! : "_"
    let category = input.category ?? "_"
    return "list|s\(input.stationId)|u\(userLat),\(userLon)|m\(mapLat),\(mapLon)|k\(keyword)|c\(category)|p\(input.page)|sz\(input.size)|so\(input.sort)"
  }

  /// Detail 캐시 키 — 사용자 위치 ~100m grid에 placeId 결합
  /// 위치가 grid 밖으로 이동하면 cache miss → API 재호출 → walkTime 갱신
  static func detail(input: PlaceDetailInput) -> String {
    let userLat = quantize(input.userLat, precision: 3)  // ~100m
    let userLon = quantize(input.userLon, precision: 3)
    return "detail|p\(input.placeId)|s\(input.stationId)|u\(userLat),\(userLon)"
  }
}
