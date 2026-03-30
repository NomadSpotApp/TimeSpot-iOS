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
    provider: MoyaProvider<PlaceService> = MoyaProvider<PlaceService>.default,
  ) {
    self.provider = provider
  }

  // MARK: - 장소 관련 api
  public func fetchPlaces(
    _ input: PlaceSearchInput
  ) async throws -> PlaceSearchPageEntity {
    let body = FetchPlaceRequest(
      stationId: input.stationId,
      userLat: input.userLat,
      userLon: input.userLon,
      remainingMinutes: input.remainingMinutes,
      mapLat: input.mapLat,
      mapLon: input.mapLon,
      keyword: input.keyword,
      category: input.category,
      page: input.page,
      size: input.size,
      sort: input.sort
    )
    let dto: PlaceSearchDTOModel = try await provider.request(.fetchPlace(body: body))
    return dto.data.toDomain()
  }

  public func detailPlaces(
    _ input: PlaceDetailInput
  ) async throws -> PlaceDetailEntity {
    let body: PlaceDetailRequest = .init(
      stationId: input.stationId,
      userLat: input.userLat,
      userLon: input.userLon,
      remainingMinutes: input.remainingMinutes
    )

    let dto: PlaceDetailDTOModel = try await provider.request(.detailPlaces(placeId: input.placeId, body: body))
    return dto.data.toDomain()
  }
}
