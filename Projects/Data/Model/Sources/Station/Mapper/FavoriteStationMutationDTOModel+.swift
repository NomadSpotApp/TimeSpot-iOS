//
//  FavoriteStationMutationDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Entity

public extension FavoriteStationMutationDTOModel {
  func toDomain() -> FavoriteStationMutationEntity {
    FavoriteStationMutationEntity(
      code: code,
      message: message
    )
  }
}
