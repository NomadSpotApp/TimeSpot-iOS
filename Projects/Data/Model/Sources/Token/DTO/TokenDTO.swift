//
//  TokenDTO.swift
//  Model
//
//  Created by Wonji Suh  on 3/24/26.
//

import Foundation

public typealias TokenDTO = BaseResponseDTO<TokenResponseDTO>

// MARK: - DataClass
public struct TokenResponseDTO: Decodable, Equatable {
    let accessToken: String
    let accessTokenExpiresIn: Int
    let refreshToken: String
    let refreshTokenExpiresIn: Int

  public init(
    accessToken: String,
    accessTokenExpiresIn: Int,
    refreshToken: String,
    refreshTokenExpiresIn: Int
  ) {
    self.accessToken = accessToken
    self.accessTokenExpiresIn = accessTokenExpiresIn
    self.refreshToken = refreshToken
    self.refreshTokenExpiresIn = refreshTokenExpiresIn
  }
}

