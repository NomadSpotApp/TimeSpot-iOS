//
//  SignUpInput.swift
//  Entity
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

public struct SignUpInput {
  public let name: String
  public let provider: SocialType
  public let mapType: ExternalMapType
  public let authCode: String
  public let email: String

  public init(
    name: String,
    provider: SocialType,
    mapType: ExternalMapType,
    authCode: String,
    email: String
  ) {
    self.name = name
    self.provider = provider
    self.mapType = mapType
    self.authCode = authCode
    self.email = email
  }
}
