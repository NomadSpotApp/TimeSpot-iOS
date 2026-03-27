//
//  PlaceInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/27/26.
//

import Entity

import WeaveDI
import ComposableArchitecture

public protocol PlaceInterface: Sendable {
  func fetchPlaces(_ input: PlaceInput) async throws -> [PlaceEntity]
}


/// Profile Repository의 DependencyKey 구조체
public struct PlaceRepositoryDependency: DependencyKey {
  public static var liveValue: PlaceInterface {
    UnifiedDI.resolve(PlaceInterface.self) ?? DefaultPlaceRepositoryImpl()
  }

  public static var testValue: PlaceInterface {
    UnifiedDI.resolve(PlaceInterface.self) ?? DefaultPlaceRepositoryImpl()
  }

  public static var previewValue: PlaceInterface = liveValue
}

/// DependencyValues extension으로 간편한 접근 제공
public extension DependencyValues {
  var placeRepository: PlaceInterface {
    get { self[PlaceRepositoryDependency.self] }
    set { self[PlaceRepositoryDependency.self] = newValue }
  }
}
