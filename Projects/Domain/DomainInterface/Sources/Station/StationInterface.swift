//
//  StationInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/26/26.
//

import Entity
import ComposableArchitecture
import WeaveDI

public protocol StationInterface: Sendable {
  func fetchStations(
    userLat: Double,
    userLon: Double,
    page: Int,
    size: Int
  ) async throws -> StationListEntity

  func loadCachedStations() async throws -> StationListEntity?

  func addFavoriteStation(
    stationID: Int
  ) async throws -> FavoriteStationMutationEntity

  func deleteFavoriteStation(
    favoriteID: Int
  ) async throws -> FavoriteStationMutationEntity
}

public struct StationRepositoryDependency: DependencyKey {
  public static var liveValue: StationInterface {
    UnifiedDI.resolve(StationInterface.self) ?? DefaultStationRepositoryImpl()
  }

  public static var testValue: StationInterface {
    UnifiedDI.resolve(StationInterface.self) ?? DefaultStationRepositoryImpl()
  }

  public static var previewValue: StationInterface = liveValue
}

public extension DependencyValues {
  var stationRepository: StationInterface {
    get { self[StationRepositoryDependency.self] }
    set { self[StationRepositoryDependency.self] = newValue }
  }
}
