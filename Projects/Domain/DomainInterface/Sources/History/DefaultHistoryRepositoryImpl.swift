//
//  DefaultHistoryRepositoryImpl.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation
import Entity

final public class DefaultHistoryRepositoryImpl: HistoryInterface {
  public init() {}

  public func loadCachedMyHistory(
    sort: TravelHistorySort,
    size: Int
  ) async throws -> HistoryEntity? {
    nil
  }

  public func myHistory(
    page: Int,
    size: Int,
    sort: TravelHistorySort
  ) async throws -> HistoryEntity {
    let items: [HistoryItemEntity] = [
      .init(
        id: 1,
        stationID: 10,
        stationName: "서울역",
        placeID: "100",
        placeName: "스타벅스 서울역점",
        placeCategory: "카페",
        startTime: "2024-03-25T13:00:00",
        endTime: "2024-03-25T14:30:00",
        trainDepartureTime: "2024-03-25T15:30:00",
        totalDurationMinutes: 90,
        isInProgress: false,
        isSuccess: true,
        createdAt: "2024-03-25T13:00:00"
      ),
      .init(
        id: 2,
        stationID: 20,
        stationName: "강남역",
        placeID: "200",
        placeName: "강남역 맛집",
        placeCategory: "레스토랑",
        startTime: "2024-03-24T10:00:00",
        endTime: nil,
        trainDepartureTime: "2024-03-24T12:00:00",
        totalDurationMinutes: 0,
        isInProgress: true,
        isSuccess: false,
        createdAt: "2024-03-24T10:00:00"
      )
    ]

    return HistoryEntity(
      items: items,
      totalElements: items.count,
      totalPages: 1,
      size: size,
      page: page,
      isFirstPage: page == 1,
      isLastPage: true
    )
  }

  public func startJourney(
    input: StartJourneyInput
  ) async throws -> JourneyEntity {
    // Mock response for testing
    return JourneyEntity(
      id: 1,
      stationId: input.stationId,
      stationName: "테스트역",
      stationAddress: "테스트 주소",
      placeId: input.placeId,
      placeName: "테스트 장소",
      placeCategory: "카페",
      placeAddress: "테스트 장소 주소",
      placeLat: 37.5407599328,
      placeLng: 126.973658303,
      startTime: Date(),
      endTime: nil,
      trainDepartureTime: input.trainDepartureTime,
      totalDurationMinutes: 0,
      isInProgress: true,
      isSuccess: false,
      createdAt: Date(),
      startLat: input.lat,
      startLng: input.lng
    )
  }

  public func endJourney(
    journeyId: Int,
    isCompleted: Bool
  ) async throws -> JourneyEntity {
    // Mock response for testing
    return JourneyEntity(
      id: journeyId,
      stationId: 1,
      stationName: "테스트역",
      stationAddress: "테스트 주소",
      placeId: "1",
      placeName: "테스트 장소",
      placeCategory: "카페",
      placeAddress: "테스트 장소 주소",
      placeLat: 37.5407599328,
      placeLng: 126.973658303,
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date(),
      trainDepartureTime: Date(),
      totalDurationMinutes: 60,
      isInProgress: false,
      isSuccess: isCompleted,
      createdAt: Date().addingTimeInterval(-3600),
      startLat: nil,
      startLng: nil
    )
  }
}
