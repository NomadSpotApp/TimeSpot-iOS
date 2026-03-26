//
//  FavoriteStationMutationEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct FavoriteStationMutationEntity: Equatable, Hashable {
  public let code: Int
  public let message: String

  public init(
    code: Int,
    message: String
  ) {
    self.code = code
    self.message = message
  }
}
