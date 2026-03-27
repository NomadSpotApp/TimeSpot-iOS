//
//  PlaceDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/27/26.
//


import Foundation

import Entity

public extension PlaceResponseDTOModel {
  func toDomain() -> PlaceEntity {
    return PlaceEntity(
      placeId: placeID,
      name: name ?? "",
      category: mapCategory(category),
      lat: lat,
      lon: lon,
      address: address ?? "",
      imageURL: imageURL,
      stayableMinutes: stayableMinutes ?? 0,
      isOpen: isOpen ?? false,
      closingTime: closingTime
    )
  }

  func toDomainForFetchPlaces() -> PlaceEntity {
    return PlaceEntity(
      placeId: placeID,
      name: name ?? "",
      category: mapCategory(category),
      lat: lon,
      lon: lat,
      address: address ?? "",
      imageURL: imageURL,
      stayableMinutes: stayableMinutes ?? 0,
      isOpen: isOpen ?? false,
      closingTime: closingTime
    )
  }

  private func mapCategory(_ value: String) -> ExploreCategory {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "카페", "cafe":
      return .cafe
    case "음식점", "restaurant":
      return .restaurant
    case "액티비티", "activity":
      return .activity
    case "쇼핑", "shopping", "etc", "기타":
      return .etc
    default:
      return .etc
    }
  }
}

public extension PlaceSearchPageResponseDTO {
  func toDomain() -> PlaceSearchPageEntity {
    PlaceSearchPageEntity(
      pageable: pageable.toDomain(),
      isLastPage: last,
      numberOfElements: numberOfElements,
      isFirstPage: first,
      size: size,
      content: content.map { $0.toDomain() },
      page: number,
      sort: sort.toDomain(),
      isEmpty: empty
    )
  }
}

public extension PlacePageableResponseDTO {
  func toDomain() -> PlacePageableEntity {
    PlacePageableEntity(
      isUnpaged: unpaged,
      isPaged: paged,
      pageNumber: pageNumber,
      pageSize: pageSize,
      offset: offset,
      sort: sort.toDomain()
    )
  }
}

public extension PlaceSortResponseDTO {
  func toDomain() -> PlaceSortEntity {
    PlaceSortEntity(
      isUnsorted: unsorted,
      isSorted: sorted,
      isEmpty: empty
    )
  }
}
