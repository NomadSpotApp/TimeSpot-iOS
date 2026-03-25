//
//  LoginEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation

public struct LoginEntity: Equatable {
  public let name: String
  public let provider: SocialType
  public let token: AuthTokens
  public let isNewUser: Bool
  public let email: String
  public let mapType: ExternalMapType?
  public let mapURLScheme: String?

  public init(
    name: String,
    isNewUser: Bool,
    provider: SocialType,
    token: AuthTokens,
    email: String,
    mapType: ExternalMapType? = nil,
    mapURLScheme: String? = nil
  ) {
    self.name = name
    self.isNewUser = isNewUser
    self.provider = provider
    self.token = token
    self.email = email
    self.mapType = mapType
    self.mapURLScheme = mapURLScheme
  }
}
