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
      stationId: googlePlaceID,
      name: name,
      address: address,
      category: mapCategory(category),
      lat: lon,
      lon: lat,
      stayableMinutes: stayableMinutes
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
