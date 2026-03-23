//
//  SignUpRequestDTO.swift
//  Service
//
//  Created by Wonji Suh  on 3/23/26.
//

public struct SignUpRequestDTO: Encodable {
  public let provider: String
  public let authCode: String
  public let nickname: String
  public let email: String
  public let mapApi: String

  public init(
    provider: String,
    authCode: String,
    nickname: String,
    email: String,
    mapApi: String
  ) {
    self.provider = provider
    self.authCode = authCode
    self.nickname = nickname
    self.email = email
    self.mapApi = mapApi
  }
}
