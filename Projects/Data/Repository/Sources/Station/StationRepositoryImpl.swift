//
//  StationRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 3/26/26.
//

import DomainInterface
import Model
import Entity

import Service
import UseCase

import AsyncMoya
import Foundation
import ComposableArchitecture

public final class StationRepositoryImpl: StationInterface, @unchecked Sendable {
  @Dependency(\.keychainManager) private var keychainManager

  private let authorizedProvider: MoyaProvider<StationService>
  private let publicProvider: MoyaProvider<StationService>
  private let local: StationLocalDataSourceProtocol

  public init(
    authorizedProvider: MoyaProvider<StationService> = MoyaProvider<StationService>.authorized,
    publicProvider: MoyaProvider<StationService> = MoyaProvider<StationService>.default,
    local: StationLocalDataSourceProtocol = StationLocalDataSource()
  ) {
    self.authorizedProvider = authorizedProvider
    self.publicProvider = publicProvider
    self.local = local
  }

  public func fetchStations(
    userLat: Double,
    userLon: Double,
    page: Int,
    size: Int
  ) async throws -> StationListEntity {
    let body: StationRequest = .init(
      userLat: userLat,
      userLon: userLon,
      page: page,
      size: size,
      sort: "stationName,ASC"
    )
    // 로그인 여부에 따라 provider 분기
    // - 로그인 사용자: authorizedProvider → AuthInterceptor가 401 시 토큰 refresh,
    //   실패 시 RefreshTokenExpired 알림으로 자동 로그아웃 처리
    // - 게스트: publicProvider 사용 (불필요한 인증 흐름 회피)
    let accessToken = await keychainManager.accessToken()
    let isLoggedIn = !(accessToken?.isEmpty ?? true)
    let provider = isLoggedIn ? authorizedProvider : publicProvider

    let dto: StationDTOModel = try await provider.request(.allStation(body: body))
    let entity = dto.data.toDomain()

    // 첫 페이지만 캐시에 저장 (페이지네이션은 별도 처리 필요 시 확장)
    if page == 1 {
      try? await local.save(stations: entity)
    }

    return entity
  }

  public func loadCachedStations() async throws -> StationListEntity? {
    try await local.load()
  }

  public func addFavoriteStation(
    stationID: Int
  ) async throws -> FavoriteStationMutationEntity {
    let body: AddFavoriteStationRequest = .init(stationID: stationID)
    let response = try await authorizedProvider.requestResponse(.addFavoriteStation(body: body))
    let dto = try JSONDecoder().decode(FavoriteStationMutationDTOModel.self, from: response.data)

    guard 200..<300 ~= response.statusCode else {
      throw NSError(
        domain: "StationFavoriteError",
        code: dto.code,
        userInfo: [NSLocalizedDescriptionKey: dto.message]
      )
    }

    // 즐겨찾기 변경 시 캐시 무효화
    try? await local.clear()

    return dto.toDomain()
  }

  public func deleteFavoriteStation(
    favoriteID: Int
  ) async throws -> FavoriteStationMutationEntity {
    let response = try await authorizedProvider.requestResponse(
      .deleteFavoriteStation(favoriteID: favoriteID)
    )
    let dto = try JSONDecoder().decode(FavoriteStationMutationDTOModel.self, from: response.data)

    guard 200..<300 ~= response.statusCode else {
      throw NSError(
        domain: "StationFavoriteError",
        code: dto.code,
        userInfo: [NSLocalizedDescriptionKey: dto.message]
      )
    }

    // 즐겨찾기 변경 시 캐시 무효화
    try? await local.clear()

    return dto.toDomain()
  }
}
