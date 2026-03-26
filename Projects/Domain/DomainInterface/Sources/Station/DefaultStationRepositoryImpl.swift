//
//  DefaultStationRepositoryImpl.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation
import Entity

final public class DefaultStationRepositoryImpl: StationInterface {
  public init() {}

  public func fetchStations(
    lat: Double,
    lng: Double,
    page: Int,
    size: Int
  ) async throws -> StationListEntity {
    let favoriteStations: [StationSummaryEntity] = [
      .init(stationID: 1, name: "서울", lines: ["경부선"]),
      .init(stationID: 4, name: "동대구", lines: ["경부선"])
    ]

    let nearbyStations: [StationSummaryEntity] = [
      .init(stationID: 1, name: "서울", lines: ["경부선", "호남선", "전라선", "강릉선"])
    ]

    let stations: [StationSummaryEntity] = [
      .init(stationID: 1, name: "서울", lines: ["경부선", "호남선", "전라선", "강릉선"]),
      .init(stationID: 2, name: "용산", lines: ["호남선", "전라선"]),
      .init(stationID: 23, name: "청량리", lines: ["강릉선", "중앙선"])
    ]

    return StationListEntity(
      favoriteStations: favoriteStations,
      nearbyStations: nearbyStations,
      stations: StationPageEntity(
        content: stations,
        totalElements: stations.count,
        totalPages: 1,
        size: size,
        page: page,
        numberOfElements: stations.count,
        isFirstPage: page == 1,
        isLastPage: true,
        isEmpty: stations.isEmpty
      )
    )
  }

  public func fetchFavoriteStations(
    page: Int,
    size: Int
  ) async throws -> FavoriteStationEntity {
    let items: [FavoriteStationItemEntity] = [
      .init(
        favoriteID: 1,
        stationID: 10,
        stationName: "서울역",
        visitCount: 5,
        createdAt: "2024-03-24T16:00:00"
      ),
      .init(
        favoriteID: 2,
        stationID: 20,
        stationName: "강남역",
        visitCount: 3,
        createdAt: "2024-03-23T10:30:00"
      )
    ]

    return FavoriteStationEntity(
      items: items,
      totalElements: items.count,
      totalPages: 1,
      size: size,
      page: page,
      isFirstPage: page == 1,
      isLastPage: true
    )
  }

  public func addFavoriteStation(
    stationID: Int
  ) async throws -> FavoriteStationMutationEntity {
    FavoriteStationMutationEntity(
      code: 201,
      message: "즐겨찾기가 성공적으로 생성되었습니다."
    )
  }

  public func deleteFavoriteStation(
    favoriteID: Int
  ) async throws -> FavoriteStationMutationEntity {
    FavoriteStationMutationEntity(
      code: 200,
      message: "즐겨찾기가 성공적으로 삭제되었습니다."
    )
  }
}
