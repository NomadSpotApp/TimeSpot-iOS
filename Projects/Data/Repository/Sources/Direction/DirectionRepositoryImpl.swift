//
//  DirectionRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

import DomainInterface
import Entity
import Service
import Model
import Moya
import LogMacro

@preconcurrency import AsyncMoya

public final class DirectionRepositoryImpl: DirectionInterface, @unchecked Sendable {

  private let provider: MoyaProvider<NaverDirectionService>

  public init(
    provider: MoyaProvider<NaverDirectionService> = MoyaProvider<NaverDirectionService>.default
  ) {
    self.provider = provider
  }

  public func getRoute(
    from start: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    option: RouteOption
  ) async throws -> RouteInfo {

    let startCoord = "\(start.longitude),\(start.latitude)"
    let goalCoord = "\(destination.longitude),\(destination.latitude)"

    do {
      if option == .walking {
        #logDebug("🚶‍♂️ [DirectionRepositoryImpl] 네이버 도보 경로 검색")
        let walkingResponse: NaverWalkingResponse = try await provider.request(.walking(start: startCoord, goal: goalCoord))
        return walkingResponse.toDomain() ?? RouteInfo(paths: [], distance: 0, duration: 0)
      } else {
        #logDebug("🚗 [DirectionRepositoryImpl] 네이버 차량 경로 검색")
        let drivingResponse: NaverDirectionResponse = try await provider.request(.driving(start: startCoord, goal: goalCoord, option: option.rawValue))
        guard let routeInfo = drivingResponse.toDomain() else {
          throw DirectionError.invalidResponse
        }
        return routeInfo
      }

    } catch {
      #logDebug("❌ [DirectionRepositoryImpl] 네이버 API 호출 실패: \(error)")
      throw DirectionError.from(error)
    }
  }
}


