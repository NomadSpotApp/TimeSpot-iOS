//
//  DefaultDirectionRepository.swift
//  DomainInterface
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

import WeaveDI

/// DomainInterface에서 제공하는 DefaultDirectionRepository
public final class DefaultDirectionRepository: DirectionRepositoryInterface {

    private let implementation: any DirectionRepositoryInterface

    public init() {
        // Repository 모듈의 실제 구현체를 사용
        self.implementation = UnifiedDI.resolve(DirectionRepositoryInterface.self)
                            ?? Data.Repository.DefaultDirectionRepository()
    }

    public func getRoute(
        from start: CoreLocation.CLLocationCoordinate2D,
        to destination: CoreLocation.CLLocationCoordinate2D,
        option: RouteOption
    ) async throws -> RouteInfo {
        return try await implementation.getRoute(from: start, to: destination, option: option)
    }
}