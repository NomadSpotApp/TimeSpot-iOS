//
//  ProfileRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//

public struct ProfileRequest: Encodable {
  public let nickname: String
  public let mapApi: String

  public init(
    nickname: String,
    mapApi: String
  ) {
    self.nickname = nickname
    self.mapApi = mapApi
  }
}
