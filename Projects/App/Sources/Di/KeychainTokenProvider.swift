//
//  KeychainTokenProvider.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import Foundation

import DomainInterface
import Foundations

final class KeychainTokenProvider: TokenProviding, @unchecked Sendable {
  private let keychainManager: KeychainManagingInterface

  init(keychainManager: KeychainManagingInterface) {
    self.keychainManager = keychainManager
  }

  func accessToken() -> String? {
    // 캐싱된 토큰이 있으면 반환
    if let cached = TokenCache.shared.token {
      return cached
    }

    // 캐시가 없으면 비동기적으로 로드
    Task {
      let token = await keychainManager.accessToken()
      TokenCache.shared.token = token
    }

    // 현재는 캐시된 값 또는 nil 반환
    return TokenCache.shared.token
  }

  func saveAccessToken(_ token: String) {
    // 캐시 업데이트
    TokenCache.shared.token = token

    // 백그라운드에서 비동기적으로 저장
    Task {
      do {
        try await keychainManager.saveAccessToken(token)
      } catch {
        print("Failed to save access token: \(error)")
        // 저장 실패 시 캐시도 초기화
        TokenCache.shared.token = nil
      }
    }
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
