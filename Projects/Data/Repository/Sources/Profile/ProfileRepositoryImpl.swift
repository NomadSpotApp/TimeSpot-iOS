//
//  ProfileRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 3/25/26.
//

import DomainInterface
import Model
import Entity

import Service


import Moya
import AsyncMoya

public class ProfileRepositoryImpl: ProfileInterface, @unchecked Sendable {
  private let provider: MoyaProvider<ProfileService>

  public init(
    provider: MoyaProvider<ProfileService> = MoyaProvider<ProfileService>.authorized,
  ) {
    self.provider = provider
  }

  public func fetchUser() async throws -> ProfileEntity {
    do {
      let response = try await provider.requestResponse(.fetchProfile)

      if (200...299).contains(response.statusCode) {
        let dto = try JSONDecoder().decode(ProfileDTOModel.self, from: response.data)
        return dto.data.toDomain()
      }

      if let errorResponse = try? JSONDecoder().decode(ProfileErrorResponseDTO.self, from: response.data) {
        if errorResponse.message.contains("잘못된 AccessToken")
          || errorResponse.message.contains("유효하지 않은 토큰") {
          throw ProfileError.profileAccessDenied
        }
        throw ProfileError.unknownError(errorResponse.message)
      }

      throw ProfileError.unknownError("statusCodeError(\(response.statusCode))")
    } catch let error as ProfileError {
      throw error
    } catch let error as MoyaError {
      switch error {
      case .statusCode(let response):
        if let errorResponse = try? JSONDecoder().decode(ProfileErrorResponseDTO.self, from: response.data) {
          if errorResponse.message.contains("잘못된 AccessToken")
            || errorResponse.message.contains("유효하지 않은 토큰") {
            throw ProfileError.profileAccessDenied
          }
          throw ProfileError.unknownError(errorResponse.message)
        }
        throw ProfileError.unknownError("statusCodeError(\(response.statusCode))")

      case .underlying(_, let response):
        if let response,
           let errorResponse = try? JSONDecoder().decode(ProfileErrorResponseDTO.self, from: response.data) {
          if errorResponse.message.contains("잘못된 AccessToken")
            || errorResponse.message.contains("유효하지 않은 토큰") {
            throw ProfileError.profileAccessDenied
          }
          throw ProfileError.unknownError(errorResponse.message)
        }
        throw ProfileError.unknownError(error.localizedDescription)

      default:
        throw ProfileError.unknownError(error.localizedDescription)
      }
    } catch {
      throw ProfileError.unknownError(error.localizedDescription)
    }
  }
}

private struct ProfileErrorResponseDTO: Decodable {
  let code: Int
  let message: String
}
