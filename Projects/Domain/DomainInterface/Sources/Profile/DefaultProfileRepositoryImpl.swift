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

  public func loadCachedUser() async throws -> ProfileEntity? {
    nil
  }

  public func fetchUser() async throws -> Entity.ProfileEntity {
    return ProfileEntity(
      email: "test@example.com",
      nickname: "Mock User",
      mapType: .appleMap,
      provider: .apple,
      totalVisitCount: 24,
      totalJourneyMinutes: 320
    )
  }

  public func editUser(
    mapType: ExternalMapType
  ) async throws -> LoginEntity {
    return LoginEntity(
      name: "테스터",
      isNewUser: false,
      provider: .apple,
      token: AuthTokens(
        accessToken: "mock_access_token_\(UUID().uuidString)",
        refreshToken: "mock_refresh_token_\(UUID().uuidString)"
      ),
      email: "test@example.com",
      mapType: mapType,
      mapURLScheme: nil
    )
  }

  public func fetchNotificationSettings() async throws -> NotificationEntity {
    NotificationEntity(
      settings: [
        .init(option: .departureTime, isEnabled: true, isEditable: false),
        .init(option: .fiveMinutesBefore, isEnabled: false, isEditable: true),
        .init(option: .tenMinutesBefore, isEnabled: false, isEditable: true),
        .init(option: .fifteenMinutesBefore, isEnabled: false, isEditable: true)
      ],
      updatedAt: "2024-01-15T10:30:00"
    )
  }

  public func editNotificationSettings(
    notificationSettings: [NotificationOption]
  ) async throws -> NotificationEntity {
    NotificationEntity(
      settings: [
        .init(option: .departureTime, isEnabled: true, isEditable: false),
        .init(option: .fiveMinutesBefore, isEnabled: notificationSettings.contains(.fiveMinutesBefore), isEditable: true),
        .init(option: .tenMinutesBefore, isEnabled: notificationSettings.contains(.tenMinutesBefore), isEditable: true),
        .init(option: .fifteenMinutesBefore, isEnabled: notificationSettings.contains(.fifteenMinutesBefore), isEditable: true)
      ],
      updatedAt: "2024-01-15T10:30:00"
    )
  }
}
