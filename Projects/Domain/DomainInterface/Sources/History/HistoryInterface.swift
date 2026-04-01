//
//  HistoryInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/26/26.
//

import Entity
import ComposableArchitecture
import WeaveDI

public protocol HistoryInterface: Sendable {
  func myHistory(
    page: Int,
    size: Int,
    sort: TravelHistorySort
  ) async throws -> HistoryEntity

  func startJourney(
    input: StartJourneyInput
  ) async throws -> JourneyEntity

  func endJourney(
    journeyId: Int,
    isCompleted: Bool
  ) async throws -> JourneyEntity
}

public struct HistoryRepositoryDependency: DependencyKey {
  public static var liveValue: HistoryInterface {
    UnifiedDI.resolve(HistoryInterface.self) ?? DefaultHistoryRepositoryImpl()
  }

  public static var testValue: HistoryInterface {
    UnifiedDI.resolve(HistoryInterface.self) ?? DefaultHistoryRepositoryImpl()
  }

  public static var previewValue: HistoryInterface = liveValue
}

public extension DependencyValues {
  var historyRepository: HistoryInterface {
    get { self[HistoryRepositoryDependency.self] }
    set { self[HistoryRepositoryDependency.self] = newValue }
  }
}
