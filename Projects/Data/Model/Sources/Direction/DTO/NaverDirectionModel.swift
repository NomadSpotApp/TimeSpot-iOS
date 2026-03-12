//
//  NaverDirectionModel.swift
//  Model
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

// MARK: - Walking Response Models
public struct NaverWalkingResponse: Codable {
    public let route: WalkingRouteResponse
}

public struct WalkingRouteResponse: Codable {
    public let trafast: [WalkingRouteDetail]?
}

public struct WalkingRouteDetail: Codable {
    public let summary: WalkingRouteSummary
    public let path: [RoutePoint]
    public let guide: [WalkingGuide]
}

public struct WalkingRouteSummary: Codable {
    public let distance: Int
    public let duration: Int
}

public struct WalkingGuide: Codable {
    public let pointIndex: [Int]
}

// MARK: - Driving Response Models
public struct NaverDirectionResponse: Codable {
    public let route: RouteResponse
}

public struct RouteResponse: Codable {
    public let trafast: [RouteDetail]?
}

public struct RouteDetail: Codable {
    public let summary: RouteSummary
    public let path: [RoutePoint]
}

public struct RouteSummary: Codable {
    public let distance: Int
    public let duration: Int
    public let tollFare: Int
    public let taxiFare: Int
}

// MARK: - Common Models
public struct RoutePoint: Codable {
    public let lat: Double
    public let lng: Double
}

