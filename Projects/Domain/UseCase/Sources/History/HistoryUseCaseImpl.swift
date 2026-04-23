//
//  HistoryUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/26/26.
//

import DomainInterface
import Entity

import WeaveDI
import ComposableArchitecture

public struct HistoryUseCaseImpl: HistoryInterface {
  @Dependency(\.historyRepository) var repository

  public init() {}

  // MARK: - 히스토리 정보
  public func myHistory(
    page: Int,
    size: Int,
    sort: TravelHistorySort
  ) async throws -> HistoryEntity {
    return try await repository.myHistory(page: page, size: size, sort: sort)
  }

  public func loadCachedMyHistory(
    sort: TravelHistorySort,
    size: Int
  ) async throws -> HistoryEntity? {
    return try await repository.loadCachedMyHistory(sort: sort, size: size)
  }

  // MARK: - 여정 관리
  public func startJourney(
    input: StartJourneyInput
  ) async throws -> JourneyEntity {
    return try await repository.startJourney(input: input)
  }

  public func endJourney(
    journeyId: Int,
    isCompleted: Bool
  ) async throws -> JourneyEntity {
    return try await repository.endJourney(journeyId: journeyId, isCompleted: isCompleted)
  }
}


extension HistoryUseCaseImpl: DependencyKey {
  static public var liveValue: HistoryInterface = HistoryUseCaseImpl()
  static public var testValue: HistoryInterface = HistoryUseCaseImpl()
  static public var previewValue: HistoryInterface = HistoryUseCaseImpl()
}

public extension DependencyValues {
  var historyUseCase: HistoryInterface {
    get { self[HistoryUseCaseImpl.self] }
    set { self[HistoryUseCaseImpl.self] = newValue }
  }
}
