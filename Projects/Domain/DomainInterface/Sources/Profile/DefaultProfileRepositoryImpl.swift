//
//  DefaultProfileRepositoryImpl.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation
import Entity

/// Profile Repository의 기본 구현체 (테스트/프리뷰용)
final public class DefaultProfileRepositoryImpl: ProfileInterface {
  public init() {}

  public func fetchUser() async throws -> Entity.ProfileEntity {
    return ProfileEntity(
      email: "test@example.com",
      nickname: "Mock User",
      mapType: .appleMap,
      provider: .apple
    )
  }
}
