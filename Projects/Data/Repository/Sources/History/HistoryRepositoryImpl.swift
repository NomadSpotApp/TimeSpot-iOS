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

  public init(
    provider: MoyaProvider<HistoryService> = MoyaProvider<HistoryService>.authorized,
  ) {
    self.provider = provider
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
    return dto.data.toDomain()
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
