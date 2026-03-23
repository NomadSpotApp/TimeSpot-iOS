//
//  LoginResponseDTO.swift
//  Model
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

// MARK: - LoginResponse
public typealias LoginDTOModel = BaseResponseDTO<LoginResponseDTO>

// MARK: - LoginResponseDTO
public struct LoginResponseDTO: Decodable, Equatable {
  let accessToken: String?
  let accessTokenExpiresIn: Int?
  let refreshToken: String?
  let refreshTokenExpiresIn: Int?
  let map: Map?
  let socialType: String
  let newUser: Bool?
  let userInfo: UserInfo?

  public init(
    accessToken: String? = nil,
    accessTokenExpiresIn: Int? = nil,
    refreshToken: String? = nil,
    refreshTokenExpiresIn: Int? = nil,
    map: Map? = nil,
    socialType: String,
    newUser: Bool? = nil,
    userInfo: UserInfo? = nil
  ) {
    self.accessToken = accessToken
    self.accessTokenExpiresIn = accessTokenExpiresIn
    self.refreshToken = refreshToken
    self.refreshTokenExpiresIn = refreshTokenExpiresIn
    self.map = map
    self.socialType = socialType
    self.newUser = newUser
    self.userInfo = userInfo
  }

}

// MARK: - Map
public struct Map: Decodable, Equatable {
  let mapName: String
  let mapURLScheme: String?

  enum CodingKeys: String, CodingKey {
    case mapName
    case mapURLScheme = "mapUrlScheme"
  }

  public init(mapName: String, mapURLScheme: String? = nil) {
    self.mapName = mapName
    self.mapURLScheme = mapURLScheme
  }
}

// MARK: - UserInfo
public struct UserInfo: Decodable, Equatable {
  let email: String
  let nickname: String?


  public init(
    email: String,
    nickname: String?
  ) {
    self.email = email
    self.nickname = nickname
  }
}
