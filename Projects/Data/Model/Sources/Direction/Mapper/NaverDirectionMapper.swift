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
    // 모든 경로 옵션 확인 및 최적 경로 선택
    let allRoutes = [
      self.route.trafast?.first,      // 빠른 길
      self.route.tracomfort?.first,   // 편한 길
      self.route.traoptimal?.first,   // 최적
      self.route.traavoidtoll?.first  // 통행료 회피
    ].compactMap { $0 }

    guard let optimalRoute = selectOptimalRoute(from: allRoutes) else {
      return RouteInfo(paths: [], distance: 0, duration: 0)
    }

    // 전체 경로 좌표 사용 (끊어짐 없는 연속 경로)
    let coordinates = optimalRoute.path.map { pathPoint in
      CLLocationCoordinate2D(latitude: pathPoint.lat, longitude: pathPoint.lng)
    }

    return RouteInfo(
      paths: coordinates,
      distance: optimalRoute.summary.distance,
      duration: optimalRoute.summary.duration / 60000, // 밀리초를 분으로 변환
      tollFare: 0,
      taxiFare: 0
    )
  }

  private func selectOptimalRoute(from routes: [WalkingRouteDetail]) -> WalkingRouteDetail? {
    guard !routes.isEmpty else { return nil }

    // 최적 경로 선택 로직: 시간과 거리의 조합으로 판단
    return routes.min { route1, route2 in
      let score1 = Double(route1.summary.duration) * 0.7 + Double(route1.summary.distance) * 0.3
      let score2 = Double(route2.summary.duration) * 0.7 + Double(route2.summary.distance) * 0.3
      return score1 < score2
    }
  }
}

public extension NaverDirectionResponse {
  func toDomain() -> RouteInfo? {
    // 모든 경로 옵션 확인 및 최적 경로 선택
    let allRoutes = [
      self.route.trafast?.first,      // 빠른 길
      self.route.tracomfort?.first,   // 편한 길
      self.route.traoptimal?.first,   // 최적
      self.route.traavoidtoll?.first  // 통행료 회피
    ].compactMap { $0 }

    guard let optimalRoute = selectOptimalRoute(from: allRoutes) else {
      return nil
    }

    let coordinates = optimalRoute.path.map { pathPoint in
      CLLocationCoordinate2D(latitude: pathPoint.lat, longitude: pathPoint.lng)
    }

    return RouteInfo(
      paths: coordinates,
      distance: optimalRoute.summary.distance,
      duration: optimalRoute.summary.duration / 60000,
      tollFare: optimalRoute.summary.tollFare,
      taxiFare: optimalRoute.summary.taxiFare
    )
  }

  private func selectOptimalRoute(from routes: [RouteDetail]) -> RouteDetail? {
    guard !routes.isEmpty else { return nil }

    // 최적 경로 선택 로직: 시간(50%) + 거리(30%) + 통행료(20%)
    return routes.min { route1, route2 in
      let score1 = Double(route1.summary.duration) * 0.5 +
                   Double(route1.summary.distance) * 0.3 +
                   Double(route1.summary.tollFare) * 0.2
      let score2 = Double(route2.summary.duration) * 0.5 +
                   Double(route2.summary.distance) * 0.3 +
                   Double(route2.summary.tollFare) * 0.2
      return score1 < score2
    }
  }
}
