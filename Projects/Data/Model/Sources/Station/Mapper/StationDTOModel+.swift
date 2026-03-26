//
//  StationDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Entity

public extension StationListResponseDTO {
  func toDomain() -> StationListEntity {
    StationListEntity(
      favoriteStations: favoriteStations.map { $0.toDomain() },
      nearbyStations: nearbyStations.map { $0.toDomain() },
      stations: stations.toDomain()
    )
  }
}

public extension StationSummaryResponseDTO {
  func toDomain() -> StationSummaryEntity {
    StationSummaryEntity(
      stationID: stationID,
      name: name,
      lines: lines
    )
  }
}

public extension StationPageResponseDTO {
  func toDomain() -> StationPageEntity {
    StationPageEntity(
      content: content.map { $0.toDomain() },
      totalElements: totalElements,
      totalPages: totalPages,
      size: size,
      page: number + 1,
      numberOfElements: numberOfElements,
      isFirstPage: first,
      isLastPage: last,
      isEmpty: empty
    )
  }
}
