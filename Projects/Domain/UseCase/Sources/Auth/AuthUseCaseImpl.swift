//
//  AuthUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/25/26.
//

import DomainInterface
import Entity

import WeaveDI
import ComposableArchitecture


public struct AuthUseCaseImpl: AuthInterface {
  @Dependency(\.authRepository) var repository

  public init() {}

  public func login(
    provider: Entity.SocialType,
    token: String
  ) async throws -> Entity.LoginEntity {
    return try await repository.login(provider: provider, token: token)
  }

  public func refresh() async throws -> Entity.AuthTokens {
    return try await repository.refresh()
  }

  public func logout() async throws -> Entity.LogoutEntity {
    return try await repository.logout()
  }

  public func withDraw() async throws -> Entity.LogoutEntity {
    return try await repository.withDraw()
  }

  public func updateSessionCredential(with tokens: Entity.AuthTokens)  {
    return repository.updateSessionCredential(with: tokens)
  }

  public func initializeSessionCredential() async {
    // Repository의 AuthSessionManager credential 초기화
    await repository.initializeSessionCredential()
  }

  public func registerNotification(
    with deviceToken: String
  ) async throws -> RegisterNotificationEntity {
    return try await repository.registerNotification(with: deviceToken)
  }
}


extension AuthUseCaseImpl: DependencyKey {
  static public var liveValue: AuthInterface = AuthUseCaseImpl()
  static public var testValue: AuthInterface = AuthUseCaseImpl()
  static public var previewValue: AuthInterface = AuthUseCaseImpl()
}

public extension DependencyValues {
  var authUseCase: AuthInterface {
    get { self[AuthUseCaseImpl.self] }
    set { self[AuthUseCaseImpl.self] = newValue }
  }
}
