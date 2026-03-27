//
//  PlaceRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 3/27/26.
//

import DomainInterface
import Model
import Entity

import Service
import Dependencies
import LogMacro

import AsyncMoya

public final class PlaceRepositoryImpl: PlaceInterface, @unchecked Sendable {
  private let provider: MoyaProvider<PlaceService>

  public init(
    provider: MoyaProvider<PlaceService> = MoyaProvider<PlaceService>.authorized,
  ) {
    self.provider = provider
  }

  // MARK: - 장소 관련 api
  public func fetchPlaces(
    _ input: PlaceInput
  ) async throws -> [PlaceEntity] {
    let body: PlaceRequest = .init(
      userLat: input.userLat,
      userLon: input.userLon,
      mapLat: input.mapLat,
      mapLon: input.mapLon,
      stationId: input.stationId,
      remainingMinutes: input.remainingMinutes
    )
    let dto: PlaceDTOModel = try await provider.request(.fetchPlaces(body: body))
    return dto.data.map { $0.toDomain() }
  }
}
