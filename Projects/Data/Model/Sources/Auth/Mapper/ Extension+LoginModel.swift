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

    let mapType: ExternalMapType? = if let mapName = self.map?.mapName {
      switch mapName.uppercased() {
      case "GOOGLE", "구글":
        .googleMap
      case "NAVER", "네이버", "네이버지도":
        .naverMap
      case "APPLE", "애플", "지도":
        .appleMap
      default:
        nil
      }
    } else {
      nil
    }

    return LoginEntity(
      name: self.userInfo?.nickname ?? "",
      isNewUser: self.newUser ?? false,
      provider: provider,
      token: token,
      email: self.userInfo?.email ?? "",
      mapType: mapType,
      mapURLScheme: self.map?.mapURLScheme
    )
  }
}
