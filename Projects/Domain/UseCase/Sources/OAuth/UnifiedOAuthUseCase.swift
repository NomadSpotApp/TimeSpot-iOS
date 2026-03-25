//
//  UnifiedOAuthUseCase.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation
import Dependencies
import AuthenticationServices
@preconcurrency import Entity
import DomainInterface
import Sharing
import LogMacro

/// 통합 OAuth UseCase - 로그인/회원가입 플로우를 하나로 통합
public struct UnifiedOAuthUseCase {
  @Dependency(\.authRepository) private var authRepository: AuthInterface
  @Dependency(\.appleOAuthProvider) private var appleProvider: AppleOAuthProviderInterface
  @Dependency(\.googleOAuthProvider) private var googleProvider: GoogleOAuthProviderInterface
  @Dependency(\.keychainManager) private var keychainManager: KeychainManaging
  @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
  @Shared(.appStorage("appleUserName")) var savedAppleUserName: String?

  public init() {}
}

// MARK: - Public Interface

public extension UnifiedOAuthUseCase {

  /// 통합 소셜 로그인 처리
  func socialLogin(
    with socialType: SocialType,
    appleCredential: ASAuthorizationAppleIDCredential? = nil,
    nonce: String? = nil,
    googleToken: String? = nil
  ) async throws -> LoginEntity {
    switch socialType {
    case .apple:
      guard let credential = appleCredential, let nonce = nonce else {
        throw AuthError.invalidCredential("Apple 로그인에 필요한 credential 또는 nonce가 없습니다")
      }
      return try await appleLogin(credential: credential, nonce: nonce)
    case .google:
      guard let token = googleToken else {
        throw AuthError.invalidCredential("Google 로그인에 필요한 token이 없습니다")
      }
      return try await googleLogin(token: token)
    }
  }

  /// Apple 로그인 처리
  func appleLogin(
    credential: ASAuthorizationAppleIDCredential,
    nonce: String
  ) async throws -> LoginEntity {
    let payload = try await appleProvider.signInWithCredential(
      credential: credential,
      nonce: nonce
    )
    Log.debug("apple authcode", payload.authorizationCode)

    // Apple 로그인 시 이름 저장 로직 개선
    let userName: String = {
      if let displayName = payload.displayName, !displayName.isEmpty {
        // 새로운 이름이 있으면 UserDefaults에 저장
        self.$savedAppleUserName.withLock { $0 = displayName }
        return displayName
      } else {
        // 이름이 없으면 이전에 저장된 이름 사용, 그것도 없으면 빈 문자열
        return self.savedAppleUserName ?? ""
      }
    }()

    self.$userSession.withLock {
      $0.name = userName
      $0.provider = .apple
      $0.authCode = payload.authorizationCode ?? ""
    }


    let loginEntity = try await authRepository.login(
      provider: .apple,
      token: payload.idToken
    )

    print("애플 코드 \(payload.authorizationCode ?? "")")

    self.$userSession.withLock {
      $0.name = savedAppleUserName ?? ""
      $0.provider = .apple
      $0.email = loginEntity.email
      $0.authCode = payload.authorizationCode ?? ""
    }

    try await keychainManager.save(
      accessToken: loginEntity.token.accessToken,
      refreshToken: loginEntity.token.refreshToken
    )

    // AuthSessionManager의 credential도 업데이트
    authRepository.updateSessionCredential(with: loginEntity.token)

    return loginEntity
  }

  /// Google 로그인 처리
  func googleLogin(
    token: String
  ) async throws -> LoginEntity {
    let payload = try await googleProvider.signInWithToken(token: token)
    self.$userSession.withLock { $0.authCode = payload.authorizationCode ?? "" }
    self.$userSession.withLock {
      $0.name = payload.displayName ?? ""
      $0.provider = .google
      $0.authCode = payload.authorizationCode ?? ""
    }
    let loginEntity = try await authRepository.login(
      provider: .google,
      token: payload.idToken
    )

    self.$userSession.withLock {
      $0.email = loginEntity.email
    }


    try await keychainManager.save(
      accessToken: loginEntity.token.accessToken,
      refreshToken: loginEntity.token.refreshToken
    )

    // AuthSessionManager의 credential도 업데이트
    authRepository.updateSessionCredential(with: loginEntity.token)
    return loginEntity
  }



  /// OAuth 플로우 처리 (TCA용)
  func processOAuthFlow(
    with socialType: SocialType,
    appleCredential: ASAuthorizationAppleIDCredential? = nil,
    nonce: String? = nil,
    googleToken: String? = nil
  ) async -> Result<LoginEntity, AuthError> {
    do {
      let result = try await socialLogin(
        with: socialType,
        appleCredential: appleCredential,
        nonce: nonce,
        googleToken: googleToken
      )
      return .success(result)
    } catch let error as AuthError {
      return .failure(error)
    } catch {
      return .failure(.unknownError(error.localizedDescription))
    }
  }
}

// MARK: - Dependencies Registration

extension UnifiedOAuthUseCase: DependencyKey {
  public static let liveValue = UnifiedOAuthUseCase()
  public static let testValue = UnifiedOAuthUseCase()
  public static let previewValue = UnifiedOAuthUseCase()
}

extension DependencyValues {
  public var unifiedOAuthUseCase: UnifiedOAuthUseCase {
    get { self[UnifiedOAuthUseCase.self] }
    set { self[UnifiedOAuthUseCase.self] = newValue }
  }
}
