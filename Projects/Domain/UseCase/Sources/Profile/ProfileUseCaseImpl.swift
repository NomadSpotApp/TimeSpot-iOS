//
//  ProfileUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation
import DomainInterface

import WeaveDI
import Entity
import ComposableArchitecture


public struct ProfileUseCaseImpl: ProfileInterface {
  @Dependency(\.profileRepository) var repository
  @Dependency(\.keychainManager) private var keychainManager: KeychainManaging
  @Dependency(\.authRepository) private var authRepository: AuthInterface
  @Shared(.appStorage("mapUrlScheme")) var mapURLScheme: String?

  public init() {}

  public func fetchUser() async throws -> ProfileEntity {
    return try await repository.fetchUser()
  }

  public func editUser(
    mapType: ExternalMapType
  ) async throws -> LoginEntity {
    let editUserEntity = try await repository.editUser(mapType: mapType)

    do {
      try await keychainManager.save(
        accessToken: editUserEntity.token.accessToken,
        refreshToken: editUserEntity.token.refreshToken
      )

      authRepository.updateSessionCredential(with: editUserEntity.token)

      self.$mapURLScheme.withLock {
        $0 = editUserEntity.mapURLScheme
      }

      return editUserEntity
    } catch {
      // 토큰 저장 실패 시 일관성 유지를 위해 에러 전파
      throw error
    }
  }
}


extension ProfileUseCaseImpl: DependencyKey {
  static public var liveValue: ProfileInterface = ProfileUseCaseImpl()
  static public var testValue: ProfileInterface = ProfileUseCaseImpl()
  static public var previewValue: ProfileInterface = liveValue
}

public extension DependencyValues {
  var profileUseCase: ProfileInterface {
    get { self[ProfileUseCaseImpl.self] }
    set { self[ProfileUseCaseImpl.self] = newValue }
  }
}

