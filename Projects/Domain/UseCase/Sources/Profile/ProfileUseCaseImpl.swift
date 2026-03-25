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

  public init() {}

  public func fetchUser() async throws -> ProfileEntity {
    return try await repository.fetchUser()
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

