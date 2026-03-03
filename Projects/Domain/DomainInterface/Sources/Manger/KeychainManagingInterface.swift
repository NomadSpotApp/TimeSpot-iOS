//
//  KeychainManagingInterface.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/4/26.
//

import Foundation
import WeaveDI

public protocol KeychainManagingInterface: Sendable {
  func save(accessToken: String, refreshToken: String)
  func saveAccessToken(_ token: String)
  func saveRefreshToken(_ token: String)
  func accessToken() -> String?
  func refreshToken() -> String?
  func clear()

  // MARK: - Modern Async API (iOS 17+)
  func save(accessToken: String, refreshToken: String) async throws
  func saveAccessToken(_ token: String) async throws
  func saveRefreshToken(_ token: String) async throws
  func accessToken() async -> String?
  func refreshToken() async -> String?
  func clear() async throws
}

public struct KeychainManagerDependency: DependencyKey {
  public static var liveValue: KeychainManagingInterface {
    UnifiedDI.resolve(KeychainManagingInterface.self) ?? InMemoryKeychainManager()
  }

  public static var testValue: KeychainManagingInterface {
    InMemoryKeychainManager()
  }

  public static var previewValue: KeychainManagingInterface = testValue
}

public extension DependencyValues {
  var keychainManager: KeychainManagingInterface {
    get { self[KeychainManagerDependency.self] }
    set { self[KeychainManagerDependency.self] = newValue }
  }
}
