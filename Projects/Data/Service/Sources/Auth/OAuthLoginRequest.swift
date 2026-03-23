//
//  OAuthLoginRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

public struct OAuthLoginRequest: Encodable {
  public let provider: String
  public let idToken: String

  public init(
    provider: String,
    idToken: String
  ) {
    self.provider = provider
    self.idToken = idToken
  }
}

