//
//  HistoryDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Entity

public extension HistoryPageResponseDTO {
  func toDomain() -> HistoryEntity {
    HistoryEntity(
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

public extension HistoryItemResponseDTO {
  func toDomain() -> HistoryItemEntity {
    HistoryItemEntity(
      id: visitingHistoryID,
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
