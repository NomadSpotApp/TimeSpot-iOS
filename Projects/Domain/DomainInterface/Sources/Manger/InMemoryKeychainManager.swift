//
//  InMemoryKeychainManager.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/4/26.
//

import Foundation

public final class InMemoryKeychainManager: KeychainManagingInterface,  Sendable {
  private var accessTokenStorage: String?
  private var refreshTokenStorage: String?

  public init() {}

  public func save(accessToken: String, refreshToken: String) {
    accessTokenStorage = accessToken
    refreshTokenStorage = refreshToken
  }

  public func saveAccessToken(_ token: String) {
    accessTokenStorage = token
  }

  public func saveRefreshToken(_ token: String) {
    refreshTokenStorage = token
  }

  public func accessToken() -> String? {
    accessTokenStorage
  }

  public func refreshToken() -> String? {
    refreshTokenStorage
  }

  public func clear() {
    accessTokenStorage = nil
    refreshTokenStorage = nil
  }

  // MARK: - Modern Async API (iOS 17+)

  public func save(accessToken: String, refreshToken: String) async throws {
    accessTokenStorage = accessToken
    refreshTokenStorage = refreshToken
  }

  public func saveAccessToken(_ token: String) async throws {
    accessTokenStorage = token
  }

  public func saveRefreshToken(_ token: String) async throws {
    refreshTokenStorage = token
  }

  public func accessToken() async -> String? {
    accessTokenStorage
  }

  public func refreshToken() async -> String? {
    refreshTokenStorage
  }

  public func clear() async throws {
    accessTokenStorage = nil
    refreshTokenStorage = nil
  }
}
