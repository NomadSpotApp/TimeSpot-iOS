//
//  KeychainManager.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/4/26.
//

import Foundation

import DomainInterface
import Security
import ComposableArchitecture
import WeaveDI

public actor KeychainManager: KeychainManagingInterface {
  private let service: String

  private enum Key {
    static let accessToken = "ACCESS_TOKEN"
    static let refreshToken = "REFRESH_TOKEN"
  }

  public init(service: String = "io.dddstudy.attendance") {
    self.service = service
  }

  // MARK: - Legacy Sync API (Backward Compatibility)

  public nonisolated func save(accessToken: String, refreshToken: String) {
    Task { [weak self] in
      try? await self?.save(accessToken: accessToken, refreshToken: refreshToken)
    }
  }

  public nonisolated func saveAccessToken(_ token: String) {
    Task { [weak self] in
      try? await self?.saveAccessToken(token)
    }
  }

  public nonisolated func saveRefreshToken(_ token: String) {
    Task { [weak self] in
      try? await self?.saveRefreshToken(token)
    }
  }

  public nonisolated func accessToken() -> String? {
    // ⚠️ Sync access - use async version for better safety
    return legacyRead(for: Key.accessToken)
  }

  public nonisolated func refreshToken() -> String? {
    // ⚠️ Sync access - use async version for better safety
    return legacyRead(for: Key.refreshToken)
  }

  public nonisolated func clear() {
    Task { [weak self] in
      try? await self?.clear()
    }
  }

  // MARK: - Modern Async API (iOS 17+)

  public func save(accessToken: String, refreshToken: String) async throws {
    try save(accessToken, for: Key.accessToken)
    try save(refreshToken, for: Key.refreshToken)
  }

  public func saveAccessToken(_ token: String) async throws {
    try save(token, for: Key.accessToken)
  }

  public func saveRefreshToken(_ token: String) async throws {
    try save(token, for: Key.refreshToken)
  }

  public func accessToken() async -> String? {
    read(for: Key.accessToken)
  }

  public func refreshToken() async -> String? {
    read(for: Key.refreshToken)
  }

  public func clear() async throws {
    try delete(for: Key.accessToken)
    try delete(for: Key.refreshToken)
  }

  // MARK: - Actor Internal Methods

  private func save(_ value: String, for key: String) throws {
    let data = Data(value.utf8)
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key
    ]

    let attributes: [CFString: Any] = [
      kSecValueData: data
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var addQuery = query
      addQuery[kSecValueData] = data
      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      guard addStatus == errSecSuccess else {
        throw KeychainError.unableToSave(status: addStatus)
      }
    } else if status != errSecSuccess {
      throw KeychainError.unableToUpdate(status: status)
    }
  }

  private func read(for key: String) -> String? {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key,
      kSecReturnData: true,
      kSecMatchLimit: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private func delete(for key: String) throws {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unableToDelete(status: status)
    }
  }

  // MARK: - Legacy Support (nonisolated)

  private nonisolated func legacyRead(for key: String) -> String? {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key,
      kSecReturnData: true,
      kSecMatchLimit: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }
}

// MARK: - Error Types

public enum KeychainError: Error, LocalizedError {
  case unableToSave(status: OSStatus)
  case unableToUpdate(status: OSStatus)
  case unableToDelete(status: OSStatus)

  public var errorDescription: String? {
    switch self {
    case .unableToSave(let status):
      return "Unable to save to keychain. Status: \(status)"
    case .unableToUpdate(let status):
      return "Unable to update keychain item. Status: \(status)"
    case .unableToDelete(let status):
      return "Unable to delete from keychain. Status: \(status)"
    }
  }
}

// MARK: - TCA Dependency

public struct KeychainManagerDependency: DependencyKey {
  public static var liveValue: KeychainManagingInterface {
    UnifiedDI.resolve(KeychainManagingInterface.self) ?? KeychainManager()
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
