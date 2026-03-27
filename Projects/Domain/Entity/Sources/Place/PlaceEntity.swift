//
//  PlaceEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/27/26.
//

import  Foundation

public struct PlaceEntity: Equatable {
  public let placeId: Int
  public let name: String
  public let category: ExploreCategory
  public let address: String
  public let lat, lon: Double
  public let imageURL: String?
  public let stayableMinutes: Int
  public let isOpen: Bool
  public let closingTime: String?

  public init(
    placeId: Int,
    name: String = "",
    category: ExploreCategory,
    lat: Double,
    lon: Double,
    address: String = "",
    imageURL: String? = nil,
    stayableMinutes: Int = 0,
    isOpen: Bool = false,
    closingTime: String? = nil
  ) {
    self.placeId = placeId
    self.name = name
    self.category = category
    self.lat = lat
    self.lon = lon
    self.address = address
    self.imageURL = imageURL
    self.stayableMinutes = stayableMinutes
    self.isOpen = isOpen
    self.closingTime = closingTime
  }
}

public struct PlaceSearchPageEntity: Equatable {
  public let pageable: PlacePageableEntity
  public let isLastPage: Bool
  public let numberOfElements: Int
  public let isFirstPage: Bool
  public let size: Int
  public let content: [PlaceEntity]
  public let page: Int
  public let sort: PlaceSortEntity
  public let isEmpty: Bool

  public init(
    pageable: PlacePageableEntity,
    isLastPage: Bool,
    numberOfElements: Int,
    isFirstPage: Bool,
    size: Int,
    content: [PlaceEntity],
    page: Int,
    sort: PlaceSortEntity,
    isEmpty: Bool
  ) {
    self.pageable = pageable
    self.isLastPage = isLastPage
    self.numberOfElements = numberOfElements
    self.isFirstPage = isFirstPage
    self.size = size
    self.content = content
    self.page = page
    self.sort = sort
    self.isEmpty = isEmpty
  }
}

public struct PlacePageableEntity: Equatable {
  public let isUnpaged: Bool
  public let isPaged: Bool
  public let pageNumber: Int
  public let pageSize: Int
  public let offset: Int
  public let sort: PlaceSortEntity

  public init(
    isUnpaged: Bool,
    isPaged: Bool,
    pageNumber: Int,
    pageSize: Int,
    offset: Int,
    sort: PlaceSortEntity
  ) {
    self.isUnpaged = isUnpaged
    self.isPaged = isPaged
    self.pageNumber = pageNumber
    self.pageSize = pageSize
    self.offset = offset
    self.sort = sort
  }
}

public struct PlaceSortEntity: Equatable {
  public let isUnsorted: Bool
  public let isSorted: Bool
  public let isEmpty: Bool

  public init(
    isUnsorted: Bool,
    isSorted: Bool,
    isEmpty: Bool
  ) {
    self.isUnsorted = isUnsorted
    self.isSorted = isSorted
    self.isEmpty = isEmpty
  }
}
