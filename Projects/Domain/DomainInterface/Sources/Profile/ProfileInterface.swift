//
//  ProfileInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/25/26.
//

import Entity
import ComposableArchitecture
import WeaveDI

public protocol ProfileInterface: Sendable {
  func fetchUser() async throws -> ProfileEntity
  func editUser(
    mapType: ExternalMapType
  )  async throws -> LoginEntity
  func fetchNotificationSettings() async throws -> NotificationEntity
  func editNotificationSettings(
    notificationSettings: [NotificationOption]
  ) async throws -> NotificationEntity
}


/// Profile Repository의 DependencyKey 구조체
public struct ProfileRepositoryDependency: DependencyKey {
  public static var liveValue: ProfileInterface {
    UnifiedDI.resolve(ProfileInterface.self) ??  DefaultProfileRepositoryImpl()
  }

  public static var testValue: ProfileInterface {
    UnifiedDI.resolve(ProfileInterface.self) ??  DefaultProfileRepositoryImpl()
  }

  public static var previewValue: ProfileInterface = liveValue
}

/// DependencyValues extension으로 간편한 접근 제공
public extension DependencyValues {
  var profileRepository: ProfileInterface {
    get { self[ProfileRepositoryDependency.self] }
    set { self[ProfileRepositoryDependency.self] = newValue }
  }
}
