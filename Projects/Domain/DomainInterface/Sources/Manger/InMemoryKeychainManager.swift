//
//  InMemoryKeychainManager.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/4/26.
//

import Foundation

public final class InMemoryKeychainManager: KeychainManaging,  Sendable {
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
}
