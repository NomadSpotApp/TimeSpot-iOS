//
//  DirectionRepositoryInterface.swift
//  DomainInterface
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation

import Entity
import WeaveDI

/// 길찾기 데이터 접근을 위한 Repository 인터페이스
public protocol DirectionRepositoryInterface: Sendable {
    /// 경로 정보를 가져옵니다
    /// - Parameters:
    ///   - start: 출발지 좌표
    ///   - destination: 목적지 좌표
    ///   - option: 경로 옵션 (도보, 차량 등)
    /// - Returns: 경로 정보
    func getRoute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        option: RouteOption
    ) async throws -> RouteInfo
}

public enum DirectionRepositoryDependency: DependencyKey {
  public static var liveValue: any DirectionRepositoryInterface {
    UnifiedDI.resolve(DirectionRepositoryInterface.self) ?? DefaultDirectionRepository()
  }

  public static var testValue: any DirectionRepositoryInterface {
    UnifiedDI.resolve(DirectionRepositoryInterface.self) ?? MockDirectionRepository()
  }

  public static let previewValue: any DirectionRepositoryInterface = liveValue
}

public extension DependencyValues {
  var directionRepository: any DirectionRepositoryInterface {
    get { self[DirectionRepositoryDependency.self] }
    set { self[DirectionRepositoryDependency.self] = newValue }
  }
}