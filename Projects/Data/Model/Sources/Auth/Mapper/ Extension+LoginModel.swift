//
//  Extension+LoginModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation
import Entity

public extension LoginResponseDTO {
  func toDomain() -> LoginEntity {
    let token = AuthTokens(
      accessToken: self.accessToken ?? "",
      refreshToken: self.refreshToken ?? "",
    )

    let provider: SocialType = switch self.socialType {
      case "GOOGLE": .google
      case "APPLE": .apple
      default: .apple
    }

    return LoginEntity(
      name: self.userInfo?.nickname ?? "",
      isNewUser: self.newUser ?? false,
      provider: provider,
      token: token,
      email: self.userInfo?.email ?? ""
    )
  }
}
