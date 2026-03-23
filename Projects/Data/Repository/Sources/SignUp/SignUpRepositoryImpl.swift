//
//  SignUpRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 3/23/26.
//


import DomainInterface
import Model
import Entity
import Service

@preconcurrency import AsyncMoya

final public class SignUpRepositoryImpl: SignUpInterface {

  private let provider: MoyaProvider<SignUpService>

  public init(
    provider: MoyaProvider<SignUpService> = MoyaProvider<SignUpService>.default
  ) {
    self.provider = provider
  }

  // MARK: - 회원가입
  public func registerUser(input: SignUpInput) async throws -> LoginEntity {
    let body = SignUpRequestDTO(
      provider: input.provider.rawValue,
      authCode: input.authCode,
      nickname: input.name,
      email: input.email,
      mapApi: input.mapType.type
    )
    let dto: LoginDTOModel = try await provider.request(.signUp(body: body))
    return dto.data.toDomain()
  }
}
