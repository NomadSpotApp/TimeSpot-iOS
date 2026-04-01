//
//  DefaultPlaceRepositoryImpl.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation
import Entity

public final class DefaultPlaceRepositoryImpl: PlaceInterface {
  public init() {}

  public func fetchPlaces(_ input: PlaceSearchInput) async throws -> PlaceSearchPageEntity {
    throw NSError(
      domain: "PlaceRepository",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "PlaceRepository is not configured."]
    )
  }

  public func detailPlaces(_ input: PlaceDetailInput) async throws -> PlaceDetailEntity {
    throw NSError(
      domain: "PlaceRepository",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "PlaceRepository is not configured."]
    )
  }
}
