//
//  StationRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 3/26/26.
//

import DomainInterface
import Model
import Entity

import Service

import AsyncMoya

public final class StationRepositoryImpl: StationInterface, @unchecked Sendable {
  private let provider: MoyaProvider<StationService>

  public init(
    provider: MoyaProvider<StationService> = MoyaProvider<StationService>.authorized
  ) {
    self.provider = provider
  }

  public func fetchStations(
    lat: Double,
    lng: Double,
    page: Int,
    size: Int
  ) async throws -> StationListEntity {
    let body: StationRequest = .init(
      lat: lat,
      lng: lng,
      page: page,
      size: size,
      sort: "stationName,ASC"
    )
    let dto: StationDTOModel = try await provider.request(.allStation(body: body))
    return dto.data.toDomain()
  }

  public func fetchFavoriteStations(
    page: Int,
    size: Int
  ) async throws -> FavoriteStationEntity {
    let body: FavoriteStationRequest = .init(
      page: page,
      size: size,
      sort: "stationName,ASC"
    )
    let dto: FavoriteStationDTOModel = try await provider.request(.favoriteStation(body: body))
    return dto.data.toDomain()
  }

  public func addFavoriteStation(
    stationID: Int
  ) async throws -> FavoriteStationMutationEntity {
    let body: AddFavoriteStationRequest = .init(stationID: stationID)
    let dto: FavoriteStationMutationDTOModel = try await provider.request(.addFavoriteStation(body: body))
    return dto.toDomain()
  }

  public func deleteFavoriteStation(
    favoriteID: Int
  ) async throws -> FavoriteStationMutationEntity {
    let dto: FavoriteStationMutationDTOModel = try await provider.request(
      .deleteFavoriteStation(deleteStationId: favoriteID)
    )
    return dto.toDomain()
  }
}
