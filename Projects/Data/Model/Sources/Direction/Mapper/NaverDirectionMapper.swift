//
//  NaverDirectionMapper.swift
//  Model
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation

import Entity

// MARK: - toDomain Extensions
public extension NaverWalkingResponse {
  func toDomain() -> RouteInfo? {
    guard let route = self.route.traoptimal?.first else {
      return RouteInfo(paths: [], distance: 0, duration: 0)
    }

    // 전체 경로 좌표 사용 (끊어짐 없는 연속 경로)
    let coordinates = route.path.map { pathPoint in
      CLLocationCoordinate2D(latitude: pathPoint.lat, longitude: pathPoint.lng)
    }

    return RouteInfo(
      paths: coordinates,
      distance: route.summary.distance,
      duration: route.summary.duration / 60000, // 밀리초를 분으로 변환
      tollFare: 0,
      taxiFare: 0
    )
  }
}

public extension NaverDirectionResponse {
  func toDomain() -> RouteInfo? {
    guard let route = self.route.traoptimal?.first else {
      return nil
    }

    let coordinates = route.path.map { pathPoint in
      CLLocationCoordinate2D(latitude: pathPoint.lat, longitude: pathPoint.lng)
    }

    return RouteInfo(
      paths: coordinates,
      distance: route.summary.distance,
      duration: route.summary.duration / 60000,
      tollFare: route.summary.tollFare,
      taxiFare: route.summary.taxiFare
    )
  }
}
