//
//  ProfileDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/25/26.
//


import Entity

public extension ProfileResponseDTO {
  func toDomain() -> ProfileEntity {
    let mapType: ExternalMapType = switch self.mapAPI.uppercased() {
    case "GOOGLE":
      .googleMap
    case "NAVER":
      .naverMap
    case "APPLE":
      .appleMap
    default:
      .appleMap
    }

    let provider: SocialType = switch self.providerType.uppercased() {
    case "GOOGLE":
      .google
    case "APPLE":
      .apple
    default:
      .apple
    }

    return ProfileEntity(
      email: self.email,
      nickname: self.nickname,
      mapType: mapType,
      provider: provider
    )
  }
}
