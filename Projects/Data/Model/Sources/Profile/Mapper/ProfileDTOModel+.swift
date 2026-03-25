//
//  ProfileDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/25/26.
//


import Entity

public extension ProfileResponseDTO {
  func toDomain() -> ProfileEntity {
    return ProfileEntity(
      email: self.email,
      nickname: self.nickname,
      mapType: ExternalMapType(rawValue: self.mapAPI) ?? .appleMap,
      provider: SocialType(rawValue: self.providerType) ?? .apple
    )
  }
}
