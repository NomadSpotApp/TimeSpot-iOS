//
//  InMemoryKeychainManager.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/4/26.
//

import Foundation

public actor InMemoryKeychainManager: KeychainManagingInterface {
  private var accessTokenStorage: String?
  private var refreshTokenStorage: String?

  public init() {}

  // MARK: - Legacy Sync API (Backward Compatibility)

  public nonisolated func save(accessToken: String, refreshToken: String) {
    Task { [weak self] in
      guard let self = self else { return }
      try? await self.save(accessToken: accessToken, refreshToken: refreshToken)
    }
  }

  public nonisolated func saveAccessToken(_ token: String) {
    Task { [weak self] in
      guard let self = self else { return }
      try? await self.saveAccessToken(token)
    }
  }

  public nonisolated func saveRefreshToken(_ token: String) {
    Task { [weak self] in
      guard let self = self else { return }
      try? await self.saveRefreshToken(token)
    }
  }

  public nonisolated func accessToken() -> String? {
    // ⚠️ Sync access - use async version for better safety
    // For testing purposes, return nil in sync context
    return nil
  }

  public nonisolated func refreshToken() -> String? {
    // ⚠️ Sync access - use async version for better safety
    // For testing purposes, return nil in sync context
    return nil
  }

  public nonisolated func clear() {
    Task { [weak self] in
      guard let self = self else { return }
      try? await self.clear()
    }
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
