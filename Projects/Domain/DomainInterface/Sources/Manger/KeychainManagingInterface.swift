//
//  KeychainManagingInterface.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/4/26.
//

import Foundation

public protocol KeychainManagingInterface: Sendable {
  func save(accessToken: String, refreshToken: String) async throws
  func saveAccessToken(_ token: String) async throws
  func saveRefreshToken(_ token: String) async throws
  func accessToken() async -> String?
  func refreshToken() async -> String?
  func clear() async throws
}

// Simplified dependency injection without external frameworks
public class KeychainManagerRegistry {
  public static let shared = KeychainManagerRegistry()

  private var _implementation: KeychainManagingInterface?

  public var implementation: KeychainManagingInterface {
    get {
      return _implementation ?? InMemoryKeychainManager()
    }
    set {
      _implementation = newValue
    }
  }

  private init() {}
}
