//
//  ProfileCacheModel.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

@Model
final class ProfileCacheEntity {
  @Attribute(.unique) var cacheKey: String
  var cachedAt: Date

  var email: String
  var nickname: String
  var mapTypeRawValue: String
  var providerRawValue: String
  var totalVisitCount: Int
  var totalJourneyMinutes: Int

  init(
    cacheKey: String,
    cachedAt: Date,
    email: String,
    nickname: String,
    mapTypeRawValue: String,
    providerRawValue: String,
    totalVisitCount: Int,
    totalJourneyMinutes: Int
  ) {
    self.cacheKey = cacheKey
    self.cachedAt = cachedAt
    self.email = email
    self.nickname = nickname
    self.mapTypeRawValue = mapTypeRawValue
    self.providerRawValue = providerRawValue
    self.totalVisitCount = totalVisitCount
    self.totalJourneyMinutes = totalJourneyMinutes
  }

  // 만료: 당일
  var isExpired: Bool {
    !Calendar.current.isDate(cachedAt, inSameDayAs: Date())
  }

  func toDomain() -> ProfileEntity {
    ProfileEntity(
      email: email,
      nickname: nickname,
      mapType: ExternalMapType(rawValue: mapTypeRawValue) ?? .appleMap,
      provider: SocialType(rawValue: providerRawValue) ?? .apple,
      totalVisitCount: totalVisitCount,
      totalJourneyMinutes: totalJourneyMinutes
    )
  }
}

extension ProfileEntity {
  func toCacheModel(cacheKey: String) -> ProfileCacheEntity {
    ProfileCacheEntity(
      cacheKey: cacheKey,
      cachedAt: Date(),
      email: email,
      nickname: nickname,
      mapTypeRawValue: mapType.rawValue,
      providerRawValue: provider.rawValue,
      totalVisitCount: totalVisitCount,
      totalJourneyMinutes: totalJourneyMinutes
    )
  }
}

enum ProfileCacheKey {
  static let user = "profile.user.default"
}
