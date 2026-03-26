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

}
