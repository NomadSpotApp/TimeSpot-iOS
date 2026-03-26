//
//  FavoriteStationDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Entity

public extension FavoriteStationPageResponseDTO {
  func toDomain() -> FavoriteStationEntity {
    FavoriteStationEntity(
      items: content.map { $0.toDomain() },
      totalElements: totalElements,
      totalPages: totalPages,
      size: size,
      page: number + 1,
      isFirstPage: first,
      isLastPage: last
    )
  }
}

public extension FavoriteStationItemResponseDTO {
  func toDomain() -> FavoriteStationItemEntity {
    FavoriteStationItemEntity(
      favoriteID: favoriteID,
      stationID: stationID,
      stationName: stationName,
      visitCount: visitCount,
      createdAt: createdAt
    )
  }
}
