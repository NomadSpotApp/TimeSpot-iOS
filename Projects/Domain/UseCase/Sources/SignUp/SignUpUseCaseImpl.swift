//
//  SignUpUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/23/26.
//

import DomainInterface
import Entity

import ComposableArchitecture

public protocol SignUpUseCaseInterface: Sendable {
  func registerUser(
    userSession: UserSession
  ) async throws -> LoginEntity
}

public struct SignUpUseCaseImpl: SignUpUseCaseInterface {
  @Dependency(\.signUpRepository) var repository
  @Dependency(\.keychainManager) private var keychainManager
  @Dependency(\.authRepository) private var authRepository: AuthInterface

  public init() {

  }

  public func registerUser(
    userSession: UserSession
  ) async throws -> LoginEntity {
    let input = SignUpInput(
      name: userSession.name,
      provider: userSession.provider,
      mapType: userSession.mapType,
      authCode: userSession.authCode,
      email: userSession.email
    )

    let signUpUser = try await repository.registerUser(input: input)

    try await keychainManager.save(
      accessToken: signUpUser.token.accessToken,
      refreshToken: signUpUser.token.refreshToken
    )

    // AuthSessionManager의 credential도 업데이트
    authRepository.updateSessionCredential(with: signUpUser.token)
    
    return signUpUser

  }

}

extension SignUpUseCaseImpl: DependencyKey {
  static public var liveValue: SignUpUseCaseInterface = SignUpUseCaseImpl()
  static public var testValue: SignUpUseCaseInterface = SignUpUseCaseImpl()
  static public var previewValue: SignUpUseCaseInterface = liveValue
}

public extension DependencyValues {
  var signUpUseCase: SignUpUseCaseInterface {
    get { self[SignUpUseCaseImpl.self] }
    set { self[SignUpUseCaseImpl.self] = newValue  }
  }
}
