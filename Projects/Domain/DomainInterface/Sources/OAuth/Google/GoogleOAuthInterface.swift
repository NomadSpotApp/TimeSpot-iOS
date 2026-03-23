//
//  GoogleOAuthInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation
import WeaveDI
import Entity

/// Google OAuth Provider Interface 프로토콜
public protocol GoogleOAuthProviderInterface: Sendable {
  func signInWithToken(
    token: String
  ) async throws -> GoogleOAuthPayload
}

/// Google OAuth Provider의 DependencyKey 구조체
public struct GoogleOAuthProviderDependency: DependencyKey {
  public static var liveValue: GoogleOAuthProviderInterface {
    UnifiedDI.resolve(GoogleOAuthProviderInterface.self) ?? MockGoogleOAuthProvider()
  }

  public static var testValue: GoogleOAuthProviderInterface {
    UnifiedDI.resolve(GoogleOAuthProviderInterface.self) ?? MockGoogleOAuthProvider()
  }

  public static var previewValue: GoogleOAuthProviderInterface = testValue
}

/// DependencyValues extension으로 간편한 접근 제공
public extension DependencyValues {
  var googleOAuthProvider: GoogleOAuthProviderInterface {
    get { self[GoogleOAuthProviderDependency.self] }
    set { self[GoogleOAuthProviderDependency.self] = newValue }
  }
}

/// 테스트용 Mock 구현체
public struct MockGoogleOAuthProvider: GoogleOAuthProviderInterface {
  public init() {}

  public func signInWithToken(
    token: String
  ) async throws -> GoogleOAuthPayload {
    return GoogleOAuthPayload(idToken: "", accessToken: "", authorizationCode: "", displayName: "")
  }
}
