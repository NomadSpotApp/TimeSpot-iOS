//
//  GetRouteUseCaseInterface.swift
//  DomainInterface
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation

import Entity

/// 경로 검색 UseCase 인터페이스
public protocol GetRouteUseCaseInterface: Sendable {
    /// 경로를 검색합니다
    /// - Parameters:
    ///   - start: 출발지 좌표
    ///   - destination: 목적지 좌표
    ///   - option: 경로 옵션 (기본값: 도보)
    /// - Returns: 경로 정보
    func execute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        option: RouteOption
    ) async throws -> RouteInfo
}