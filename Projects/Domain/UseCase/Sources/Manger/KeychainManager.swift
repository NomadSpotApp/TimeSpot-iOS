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
  private let accessGroup: String?

  private enum Key {
    static let accessToken = "ACCESS_TOKEN"
    static let refreshToken = "REFRESH_TOKEN"
  }

  public init(service: String = Bundle.main.bundleIdentifier ?? "com.nomadspot.app",
             accessGroup: String? = nil) {
    self.service = service
    self.accessGroup = accessGroup
  }

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
    var query = baseQuery(for: key)

    let attributes: [CFString: Any] = [
      kSecValueData: data
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      // Item doesn't exist, create new one with security attributes
      query[kSecValueData] = data
      query[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

      let addStatus = SecItemAdd(query as CFDictionary, nil)
      guard addStatus == errSecSuccess else {
        throw KeychainError.unableToSave(status: addStatus)
      }
    } else if status != errSecSuccess {
      throw KeychainError.unableToUpdate(status: status)
    }
  }

  private func read(for key: String) -> String? {
    var query = baseQuery(for: key)
    query[kSecReturnData] = true
    query[kSecMatchLimit] = kSecMatchLimitOne

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private func delete(for key: String) throws {
    let query = baseQuery(for: key)
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unableToDelete(status: status)
    }
  }

  // MARK: - Helper Methods

  private func baseQuery(for key: String) -> [CFString: Any] {
    var query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key
    ]

    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup] = accessGroup
    }

    return query
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
