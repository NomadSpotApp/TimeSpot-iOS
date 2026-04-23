//
//  HistoryRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 3/26/26.
//

import DomainInterface
import Model
import Entity

import Service
import Dependencies
import LogMacro

import AsyncMoya

public class HistoryRepositoryImpl: HistoryInterface , @unchecked Sendable {
  private let provider: MoyaProvider<HistoryService>
  private let local: HistoryLocalDataSourceProtocol

  public init(
    provider: MoyaProvider<HistoryService> = MoyaProvider<HistoryService>.authorized,
    local: HistoryLocalDataSourceProtocol = HistoryLocalDataSource()
  ) {
    self.provider = provider
    self.local = local
  }

  // MARK: - 내 히스토리 정보

  public func myHistory(
    page: Int,
    size: Int,
    sort: TravelHistorySort
  ) async throws -> HistoryEntity {
    let safePage = max(page, 1)
    let body: MyHistoryRequest = .init(page: safePage, size: size, sort: sort.description)
    let dto: HistoryDTOModel = try await provider.request(.myHistory(body: body))
    let entity = dto.data.toDomain()

    // 첫 페이지만 캐시 저장 (페이지네이션 캐시는 비용 큼)
    if safePage == 1 {
      try? await local.saveHistory(sort: sort, size: size, history: entity)
    }
    return entity
  }

  public func loadCachedMyHistory(
    sort: TravelHistorySort,
    size: Int
  ) async throws -> HistoryEntity? {
    try await local.loadHistory(sort: sort, size: size)
  }

  public func startJourney(
    input: StartJourneyInput
  ) async throws -> JourneyEntity {
    let body = StartJourneyRequest(
      stationId: input.stationId,
      placeId: input.placeId,
      trainDepartureTime: input.trainDepartureTime,
      lat: input.lat,
      lng: input.lng
    )
    let dto: StartJourneyDTOModel = try await provider.request(.startHistory(body: body))
    return dto.data.toDomain()
  }

  public func endJourney(
    journeyId: Int,
    isCompleted: Bool
  ) async throws -> JourneyEntity {
    let body = EndJourneyRequest(
      journeyId: journeyId,
      isCompleted: isCompleted
    )
    let dto: EndJourneyDTOModel = try await provider.request(.endHistory(body: body))
    return dto.data.toDomain()
  }

}
