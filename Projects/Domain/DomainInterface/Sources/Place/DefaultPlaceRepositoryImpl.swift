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

  public func fetchPlaces(_ input: PlaceInput) async throws -> [PlaceEntity] {
    throw NSError(
      domain: "PlaceRepository",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "PlaceRepository is not configured."]
    )
  }
}
