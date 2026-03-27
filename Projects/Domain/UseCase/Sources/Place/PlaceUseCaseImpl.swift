//
//  PlaceUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/27/26.
//

import DomainInterface
import Entity

import ComposableArchitecture

public protocol PlaceUseCaseInterface: Sendable {
  func fetchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> [PlaceEntity]
}

public struct PlaceUseCaseImpl: PlaceUseCaseInterface {
  @Dependency(\.placeRepository) var repository

  public init() {}

  public func fetchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> [PlaceEntity] {
    let input = PlaceInput(
      userLat: userLat,
      userLon: userLon,
      mapLat: userSession.travelStationLat ?? 0,
      mapLon: userSession.travelStationLng ?? 0,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250
    )

    return try await repository.fetchPlaces(input)
  }
}

extension PlaceUseCaseImpl: DependencyKey {
  public static var liveValue: PlaceUseCaseInterface = PlaceUseCaseImpl()
  public static var testValue: PlaceUseCaseInterface = PlaceUseCaseImpl()
  public static var previewValue: PlaceUseCaseInterface = PlaceUseCaseImpl()
}

public extension DependencyValues {
  var placeUseCase: PlaceUseCaseInterface {
    get { self[PlaceUseCaseImpl.self] }
    set { self[PlaceUseCaseImpl.self] = newValue }
  }
}
