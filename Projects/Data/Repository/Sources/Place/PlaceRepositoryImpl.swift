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
  private let local: PlaceLocalDataSourceProtocol

  public init(
    provider: MoyaProvider<PlaceService> = MoyaProvider<PlaceService>.default,
    local: PlaceLocalDataSourceProtocol = PlaceLocalDataSource()
  ) {
    self.provider = provider
    self.local = local
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
    let entity = dto.data.toDomain()

    // Cache write (best-effort)
    let cacheKey = PlaceCacheKey.list(input: input)
    try? await local.saveList(cacheKey: cacheKey, page: entity)

    return entity
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
    let entity = dto.data.toDomain()

    // Cache write (best-effort) — 사용자 위치 기반 키 사용
    let cacheKey = PlaceCacheKey.detail(input: input)
    try? await local.saveDetail(cacheKey: cacheKey, detail: entity)

    return entity
  }

  // MARK: - Cache APIs

  public func loadCachedPlaces(
    _ input: PlaceSearchInput
  ) async throws -> PlaceSearchPageEntity? {
    let cacheKey = PlaceCacheKey.list(input: input)
    return try await local.loadList(cacheKey: cacheKey)
  }

  public func loadCachedDetailPlace(
    _ input: PlaceDetailInput
  ) async throws -> PlaceDetailEntity? {
    let cacheKey = PlaceCacheKey.detail(input: input)
    return try await local.loadDetail(cacheKey: cacheKey)
  }
}
