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
    guard let route = self.route.trafast?.first else {
      return RouteInfo(paths: [], distance: 0, duration: 0)
    }

    var allCoordinates: [CLLocationCoordinate2D] = []

    for guide in route.guide {
      for point in guide.pointIndex {
        if point >= 0 && point < route.path.count {
          let pathPoint = route.path[point]
          allCoordinates.append(CLLocationCoordinate2D(
            latitude: pathPoint.lat,
            longitude: pathPoint.lng
          ))
        }
      }
    }

    return RouteInfo(
      paths: allCoordinates,
      distance: route.summary.distance,
      duration: route.summary.duration / 60000, // 밀리초를 분으로 변환
      tollFare: 0,
      taxiFare: 0
    )
  }
}

public extension NaverDirectionResponse {
  func toDomain() -> RouteInfo? {
    guard let route = self.route.trafast?.first else {
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
