//
//  StationUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/26/26.
//

import DomainInterface
import Entity

import ComposableArchitecture

public struct StationUseCaseImpl: StationInterface {
  @Dependency(\.stationRepository) var repository

  public init() {}

  public func fetchStations(
    userLat: Double,
    userLon: Double,
    page: Int,
    size: Int
  ) async throws -> StationListEntity {
    try await repository.fetchStations(
      userLat: userLat,
      userLon: userLon,
      page: page,
      size: size
    )
  }

  public func addFavoriteStation(
    stationID: Int
  ) async throws -> FavoriteStationMutationEntity {
    try await repository.addFavoriteStation(stationID: stationID)
  }

  public func deleteFavoriteStation(
    favoriteID: Int
  ) async throws -> FavoriteStationMutationEntity {
    try await repository.deleteFavoriteStation(favoriteID: favoriteID)
  }
}

extension StationUseCaseImpl: DependencyKey {
  public static var liveValue: StationInterface = StationUseCaseImpl()
  public static var testValue: StationInterface = StationUseCaseImpl()
  public static var previewValue: StationInterface = StationUseCaseImpl()
}

public extension DependencyValues {
  var stationUseCase: StationInterface {
    get { self[StationUseCaseImpl.self] }
    set { self[StationUseCaseImpl.self] = newValue }
  }
}
