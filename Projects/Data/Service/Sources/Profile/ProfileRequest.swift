//
//  ProfileRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//

public struct ProfileRequest: Encodable {
  public let mapApi: String

  public init(
    mapApi: String
  ) {
    self.mapApi = mapApi
  }
}
