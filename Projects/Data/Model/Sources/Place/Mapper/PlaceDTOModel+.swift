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
    PlaceEntity(
      placeId: Int(placeId) ?? 0,
      name: name ?? "",
      category: mapCategory(category),
      lat: latitude,
      lon: longitude,
      address: address ?? "",
      imageURL: imageUrl,
      stayableMinutes: stayableMinutes ?? 0,
      isOpen: isOpen ?? visitable,
      closingTime: closingTime,
      distanceFromUser: distanceFromUser,
      distanceFromStation: distanceFromStation,
      walkTimeFromStation: walkTimeFromStation,
      visitable: visitable
    )
  }

  func toDomainForFetchPlaces() -> PlaceEntity {
    PlaceEntity(
      placeId: Int(placeId) ?? 0,
      name: name ?? "",
      category: mapCategory(category),
      lat: latitude,
      lon: longitude,
      address: address ?? "",
      imageURL: imageUrl,
      stayableMinutes: stayableMinutes ?? 0,
      isOpen: isOpen ?? visitable,
      closingTime: closingTime,
      distanceFromUser: distanceFromUser,
      distanceFromStation: distanceFromStation,
      walkTimeFromStation: walkTimeFromStation,
      visitable: visitable
    )
  }

  private func mapCategory(_ value: String) -> ExploreCategory {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    let category: ExploreCategory
    switch normalized {
    case "카페", "cafe":
      category = .cafe
    case "음식점", "restaurant":
      category = .restaurant
    case "액티비티", "activity":
      category = .activity
    case "관광지", "tour", "tourism":
      category = .etc  // 관광지를 etc로 매핑
    case "문화시설", "culture", "cultural":
      category = .etc  // 문화시설도 etc로 매핑
    case "쇼핑", "shopping":
      category = .shopping
    case "기타":
      category = .etc
    default:
      category = .etc
    }

    return category
  }
}

public extension PlaceSearchPageResponseDTO {
  func toDomain() -> PlaceSearchPageEntity {
    let sortEntity = sort.toDomain()
    let pageable = PlacePageableEntity(
      isUnpaged: false,
      isPaged: true,
      pageNumber: number,
      pageSize: size,
      offset: number * size,
      sort: sortEntity
    )


    return PlaceSearchPageEntity(
      pageable: pageable,
      isLastPage: !hasNext,
      numberOfElements: content.count,
      isFirstPage: number == 1,
      size: size,
      content: content.map { $0.toDomainForFetchPlaces() },
      page: number, // 서버와 클라이언트 모두 1-based 페이지 사용
      sort: sortEntity,
      isEmpty: content.isEmpty
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
