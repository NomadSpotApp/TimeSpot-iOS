//
//  ProfileEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation

// MARK: - DataClass
public struct ProfileEntity: Equatable, Hashable {
  public let email, nickname: String
  public let mapType: ExternalMapType
  public let provider: SocialType

  public init(
    email: String,
    nickname: String,
    mapType: ExternalMapType,
    provider: SocialType
  ) {
    self.email = email
    self.nickname = nickname
    self.mapType = mapType
    self.provider = provider
  }
}
