//
//  GetRouteUseCaseImpl.swift
//  UseCase
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation

import DomainInterface
import Entity
import ComposableArchitecture
import LogMacro

/// 경로 검색 비즈니스 로직을 처리하는 UseCase
public struct GetRouteUseCaseImpl: DirectionInterface {

  

    @Dependency(\.directionRepository) var repository

    public init() {}

    /// 경로를 검색합니다
    public func execute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        option: RouteOption = .walking
    ) async throws -> RouteInfo {
      #logDebug("🎯 [GetRouteUseCase] 경로 검색 시작: \(option.displayName)")

        do {
            let routeInfo = try await getRoute(
                from: start,
                to: destination,
                option: option
            )

          #logDebug("✅ [GetRouteUseCase] 경로 검색 완료: \(routeInfo.distance)m, \(routeInfo.duration)분")
            return routeInfo
        } catch {
            #logDebug("❌ [GetRouteUseCase] 경로 검색 실패: \(error)")
            throw error
        }
    }

  public func getRoute(
    from start: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    option: Entity.RouteOption
  ) async throws -> Entity.RouteInfo {
    return try await repository
      .getRoute(
        from: start,
        to: destination,
        option: option
      )
  }
}


extension GetRouteUseCaseImpl: DependencyKey {
  public static var liveValue  = GetRouteUseCaseImpl()
  public static var testValue = GetRouteUseCaseImpl()
  public static var previewValue = liveValue
}

public extension DependencyValues {
  var getRouteUseCase: GetRouteUseCaseImpl {
    get { self[GetRouteUseCaseImpl.self] }
    set { self[GetRouteUseCaseImpl.self] = newValue }
  }
}


