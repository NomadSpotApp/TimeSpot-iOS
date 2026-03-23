//
//  GoogleOAuthProvider.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/23/26.
//

import DomainInterface
import Entity

import ComposableArchitecture
import LogMacro

public struct GoogleOAuthProvider: GoogleOAuthProviderInterface, Sendable {
  @Dependency(\.googleOAuthRepository) var repository

  public init() {
  }

  public func signInWithToken(token: String) async throws -> GoogleOAuthPayload {
    let payload = try await repository.signIn()
    Log.info("google sign-in completed through repository with credential \(payload.displayName)")
    return payload
  }
}
