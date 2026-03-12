//
//  DefaultDirectionRepository.swift
//  DomainInterface
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation

import Entity

/// 기본/테스트용 Mock DirectionRepository
public final class DefaultDirectionRepository: DirectionInterface {

    public init() {}

    public func getRoute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        option: RouteOption
    ) async throws -> RouteInfo {
        // Mock 데이터 반환
        let mockPaths = [
            start,
            CLLocationCoordinate2D(
                latitude: (start.latitude + destination.latitude) / 2,
                longitude: (start.longitude + destination.longitude) / 2
            ),
            destination
        ]

        return RouteInfo(
            paths: mockPaths,
            distance: 1000, // 1km
            duration: 15,   // 15분
            tollFare: option == .walking ? 0 : 3000,
            taxiFare: option == .walking ? 0 : 10000
        )
    }
}

/// MockDirectionRepository의 별칭
public typealias MockDirectionRepository = DefaultDirectionRepository
