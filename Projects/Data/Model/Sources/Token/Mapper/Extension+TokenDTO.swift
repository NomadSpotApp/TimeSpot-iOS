//
//  Extension+TokenDTO.swift
//  Model
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation
import Entity

public extension TokenResponseDTO {
  func toDomain() -> AuthTokens {
    return AuthTokens(
      accessToken: self.accessToken,
      refreshToken: self.refreshToken
    )


  }
}
