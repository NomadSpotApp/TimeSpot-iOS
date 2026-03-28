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
import Foundation

public final class StationRepositoryImpl: StationInterface, @unchecked Sendable {
  private let authorizedProvider: MoyaProvider<StationService>
  private let publicProvider: MoyaProvider<StationService>

  public init(
    authorizedProvider: MoyaProvider<StationService> = MoyaProvider<StationService>.authorized,
    publicProvider: MoyaProvider<StationService> = MoyaProvider<StationService>()
  ) {
    self.authorizedProvider = authorizedProvider
    self.publicProvider = publicProvider
  }

  public func fetchStations(
    userLat: Double,
    userLon: Double,
    page: Int,
    size: Int
  ) async throws -> StationListEntity {
    let body: StationRequest = .init(
      userLat: userLat,
      userLon: userLon,
      page: page,
      size: size,
      sort: "stationName,ASC"
    )
    let dto: StationDTOModel = try await publicProvider.request(.allStation(body: body))
    return dto.data.toDomain()
  }

  public func addFavoriteStation(
    stationID: Int
  ) async throws -> FavoriteStationMutationEntity {
    let body: AddFavoriteStationRequest = .init(stationID: stationID)
    let response = try await authorizedProvider.requestResponse(.addFavoriteStation(body: body))
    let dto = try JSONDecoder().decode(FavoriteStationMutationDTOModel.self, from: response.data)

    guard 200..<300 ~= response.statusCode else {
      throw NSError(
        domain: "StationFavoriteError",
        code: dto.code,
        userInfo: [NSLocalizedDescriptionKey: dto.message]
      )
    }

    return dto.toDomain()
  }

  public func deleteFavoriteStation(
    favoriteID: Int
  ) async throws -> FavoriteStationMutationEntity {
    let response = try await authorizedProvider.requestResponse(
      .deleteFavoriteStation(favoriteID: favoriteID)
    )
    let dto = try JSONDecoder().decode(FavoriteStationMutationDTOModel.self, from: response.data)

    guard 200..<300 ~= response.statusCode else {
      throw NSError(
        domain: "StationFavoriteError",
        code: dto.code,
        userInfo: [NSLocalizedDescriptionKey: dto.message]
      )
    }

    return dto.toDomain()
  }
}
