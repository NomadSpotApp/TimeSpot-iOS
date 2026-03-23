//
//  DefaultSignUpRepositoryImpl.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 7/23/25.
//  Moved from Repository module
//

import Foundation
import Entity

/// SignUp Repository의 기본 구현체 (테스트/프리뷰용)
final public class DefaultSignUpRepositoryImpl: SignUpInterface, @unchecked Sendable {

  // MARK: - Configuration
  public enum Configuration {
    case success
    case failure
    case invalidInviteCode
    case expiredInviteCode
    case networkError
    case serverError
    case customDelay(TimeInterval)

    var shouldSucceed: Bool {
      switch self {
      case .success, .customDelay:
        return true
      case .failure, .invalidInviteCode, .expiredInviteCode, .networkError, .serverError:
        return false
      }
    }

    var delay: TimeInterval {
      switch self {
      case .customDelay(let delay):
        return delay
      default:
        return 1.0 // 실제 네트워크 지연 시뮬레이션
      }
    }

    var signUpError: SignUpError? {
      switch self {
      case .success, .customDelay:
        return nil
      case .failure:
        return .accountCreationFailed
      case .invalidInviteCode:
        return .invalidInviteCode
      case .expiredInviteCode:
        return .expiredInviteCode
      case .networkError:
        return .networkError
      case .serverError:
        return .serverError("서버 내부 오류")
      }
    }
  }

  // MARK: - Properties (Test implementation - @unchecked Sendable)
  private var configuration: Configuration = .success
  private var registerCallCount = 0
  private var validateCallCount = 0
  private var checkEmailCallCount = 0
  private var lastCall: Date?

  // MARK: - Initialization

  public init(configuration: Configuration = .success) {
    self.configuration = configuration
  }

  // MARK: - Configuration Methods

  public func setConfiguration(_ configuration: Configuration) {
    self.configuration = configuration
    registerCallCount = 0
    validateCallCount = 0
    checkEmailCallCount = 0
    lastCall = nil
  }

  public func getRegisterCallCount() -> Int { registerCallCount }
  public func getValidateCallCount() -> Int { validateCallCount }
  public func getCheckEmailCallCount() -> Int { checkEmailCallCount }
  public func getLastCall() -> Date? { lastCall }

  public func reset() {
    configuration = .success
    registerCallCount = 0
    validateCallCount = 0
    checkEmailCallCount = 0
    lastCall = nil
  }

  // MARK: - SignUpInterface Implementation

  public func registerUser(
    input: SignUpInput
  ) async throws -> LoginEntity {
    // Track call
    registerCallCount += 1
    lastCall = Date()

    // Apply delay
    if configuration.delay > 0 {
      try await Task.sleep(for: .seconds(configuration.delay))
    }

    // 입력 값 검증
    guard !input.name.isEmpty else {
      throw SignUpError.missingRequiredField("이름")
    }

    guard !input.authCode.isEmpty else {
      throw SignUpError.missingRequiredField("인증 코드")
    }

    // Configuration 기반 응답 처리
    if !configuration.shouldSucceed, let error = configuration.signUpError {
      throw error
    }

    // Success case - 더미 토큰 생성 (테스트용)
    let authTokens = AuthTokens(
      accessToken: "mock_access_token_\(UUID().uuidString)",
      refreshToken: "mock_refresh_token_\(UUID().uuidString)"
    )

    return LoginEntity(
      name: input.name,
      isNewUser: true, // 회원가입이므로 신규 사용자
      provider: input.provider,
      token: authTokens,
      email: input.email
    )
  }
}

// MARK: - Convenience Static Methods

public extension DefaultSignUpRepositoryImpl {

  /// Creates a pre-configured instance for success scenario
  static func success() -> DefaultSignUpRepositoryImpl {
    return DefaultSignUpRepositoryImpl(configuration: .success)
  }

  /// Creates a pre-configured instance for failure scenario
  static func failure() -> DefaultSignUpRepositoryImpl {
    return DefaultSignUpRepositoryImpl(configuration: .failure)
  }

  /// Creates a pre-configured instance for invalid invite code scenario
  static func invalidInviteCode() -> DefaultSignUpRepositoryImpl {
    return DefaultSignUpRepositoryImpl(configuration: .invalidInviteCode)
  }

  /// Creates a pre-configured instance for expired invite code scenario
  static func expiredInviteCode() -> DefaultSignUpRepositoryImpl {
    return DefaultSignUpRepositoryImpl(configuration: .expiredInviteCode)
  }

  /// Creates a pre-configured instance for network error scenario
  static func networkError() -> DefaultSignUpRepositoryImpl {
    return DefaultSignUpRepositoryImpl(configuration: .networkError)
  }

  /// Creates a pre-configured instance with custom delay
  static func withDelay(_ delay: TimeInterval) -> DefaultSignUpRepositoryImpl {
    return DefaultSignUpRepositoryImpl(configuration: .customDelay(delay))
  }
}
