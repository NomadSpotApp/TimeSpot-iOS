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

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // 네이버 API는 [lng, lat] 순서의 배열로 좌표를 반환
        if let coordinateArray = try? container.decode([Double].self) {
            guard coordinateArray.count >= 2 else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "좌표 배열은 최소 2개의 값이 필요합니다."))
            }
            self.lng = coordinateArray[0]  // 경도
            self.lat = coordinateArray[1]  // 위도
        } else {
            // 대안: 객체 형태 {lat: ..., lng: ...}
            let coordinateContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.lat = try coordinateContainer.decode(Double.self, forKey: .lat)
            self.lng = try coordinateContainer.decode(Double.self, forKey: .lng)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
    }

    private enum CodingKeys: String, CodingKey {
        case lat, lng
    }
}

