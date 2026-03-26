//
//  ProfileEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation

// MARK: - DataClass
public struct ProfileEntity: Equatable, Hashable {
  public let email, nickname: String
  public let mapType: ExternalMapType
  public let provider: SocialType
  public let totalVisitCount,  totalJourneyMinutes: Int

  public init(
    email: String,
    nickname: String,
    mapType: ExternalMapType,
    provider: SocialType,
    totalVisitCount: Int,
    totalJourneyMinutes: Int
  ) {
    self.email = email
    self.nickname = nickname
    self.mapType = mapType
    self.provider = provider
    self.totalVisitCount = totalVisitCount
    self.totalJourneyMinutes = totalJourneyMinutes
  }
}

// MARK: - Computed Properties
extension ProfileEntity {
  /// totalJourneyMinutes를 "00시간00분" 형태로 포맷팅
  public var formattedJourneyTime: String {
    let hours = totalJourneyMinutes / 60
    let minutes = totalJourneyMinutes % 60
    return String(format: "%02d시간%02d분", hours, minutes)
  }

  /// 시간만 필요한 경우
  public var journeyHours: Int {
    return totalJourneyMinutes / 60
  }

  /// 분만 필요한 경우 (시간 제외한 나머지 분)
  public var journeyMinutes: Int {
    return totalJourneyMinutes % 60
  }
}
