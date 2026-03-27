//
//  KeychainTokenProvider.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import Foundation
import Security

import DomainInterface
import Foundations

final class KeychainTokenProvider: TokenProviding, @unchecked Sendable {
  private enum Constants {
    static let cachedAccessTokenKey = "cached_access_token"
  }

  private let keychainManager: KeychainManagingInterface

  init(keychainManager: KeychainManagingInterface) {
    self.keychainManager = keychainManager
  }

  func accessToken() -> String? {
    // 캐싱된 토큰이 있으면 반환
    if let cached = TokenCache.shared.token {
      return cached
    }

    if let persistedToken = UserDefaults.standard.string(forKey: Constants.cachedAccessTokenKey),
       !persistedToken.isEmpty {
      TokenCache.shared.token = persistedToken
      return persistedToken
    }

    if let keychainToken = readAccessTokenFromKeychain(), !keychainToken.isEmpty {
      TokenCache.shared.token = keychainToken
      UserDefaults.standard.set(keychainToken, forKey: Constants.cachedAccessTokenKey)
      return keychainToken
    }

    // 캐시가 없으면 비동기적으로 로드
    Task {
      let token = await keychainManager.accessToken()
      TokenCache.shared.token = token
      if let token, !token.isEmpty {
        UserDefaults.standard.set(token, forKey: Constants.cachedAccessTokenKey)
      }
    }

    // 현재는 캐시된 값 또는 nil 반환
    return TokenCache.shared.token
  }

  func saveAccessToken(_ token: String) {
    // 캐시 업데이트
    TokenCache.shared.token = token
    UserDefaults.standard.set(token, forKey: Constants.cachedAccessTokenKey)

    // 백그라운드에서 비동기적으로 저장
    Task {
      do {
        try await keychainManager.saveAccessToken(token)
      } catch {
        print("Failed to save access token: \(error)")
        // 저장 실패 시 캐시도 초기화
        TokenCache.shared.token = nil
        UserDefaults.standard.removeObject(forKey: Constants.cachedAccessTokenKey)
      }
    }
  }

  private func readAccessTokenFromKeychain() -> String? {
    let service = Bundle.main.bundleIdentifier ?? "com.nomadspot.app"
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: "ACCESS_TOKEN",
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

// Thread-safe 토큰 캐시
private final class TokenCache: @unchecked Sendable {
  static let shared = TokenCache()

  private var _token: String?
  private let lock = NSLock()

  private init() {}

  var token: String? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _token
    }
    set {
      lock.lock()
      _token = newValue
      lock.unlock()
    }
  }
}
