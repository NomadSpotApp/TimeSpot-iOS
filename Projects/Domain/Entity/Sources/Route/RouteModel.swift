//
//  RouteModel.swift
//  Home
//
//  Created by Wonji Suh on 2026-03-12
//

import Foundation
import CoreLocation

// MARK: - 목적지 정보
public struct Destination: Equatable {
  public let name: String
  public let coordinate: CLLocationCoordinate2D
  public let address: String?

  public init(name: String, coordinate: CLLocationCoordinate2D, address: String? = nil) {
    self.name = name
    self.coordinate = coordinate
    self.address = address
  }

  public static func == (lhs: Destination, rhs: Destination) -> Bool {
    return lhs.name == rhs.name &&
           lhs.coordinate.latitude == rhs.coordinate.latitude &&
           lhs.coordinate.longitude == rhs.coordinate.longitude &&
           lhs.address == rhs.address
  }
}

// MARK: - 경로 정보
public struct RouteInfo: Equatable {
  public let paths: [CLLocationCoordinate2D] // 경로 좌표들
  public let distance: Int // 거리 (미터)
  public let duration: Int // 소요 시간 (분)
  public let tollFare: Int // 톨비
  public let taxiFare: Int // 택시비

  public init(
    paths: [CLLocationCoordinate2D],
    distance: Int,
    duration: Int,
    tollFare: Int = 0,
    taxiFare: Int = 0
  ) {
    self.paths = paths
    self.distance = distance
    self.duration = duration
    self.tollFare = tollFare
    self.taxiFare = taxiFare
  }

  public static func == (lhs: RouteInfo, rhs: RouteInfo) -> Bool {
    return lhs.distance == rhs.distance &&
           lhs.duration == rhs.duration &&
           lhs.tollFare == rhs.tollFare &&
           lhs.taxiFare == rhs.taxiFare &&
           lhs.paths.count == rhs.paths.count &&
           zip(lhs.paths, rhs.paths).allSatisfy { lhsCoord, rhsCoord in
             lhsCoord.latitude == rhsCoord.latitude && lhsCoord.longitude == rhsCoord.longitude
           }
  }
}

// MARK: - 길찾기 옵션
public enum RouteOption: String, CaseIterable, Equatable {
  case walking = "walking" // 도보
  case trafast = "trafast" // 실시간 빠른길
  case tracomfort = "tracomfort" // 실시간 편안한길
  case traoptimal = "traoptimal" // 실시간 최적
  case traavoidtoll = "traavoidtoll" // 무료우선
  case traavoidcaronly = "traavoidcaronly" // 자동차전용도로회피우선

  public var displayName: String {
    switch self {
    case .walking: return "도보"
    case .trafast: return "빠른길"
    case .tracomfort: return "편안한길"
    case .traoptimal: return "최적"
    case .traavoidtoll: return "무료우선"
    case .traavoidcaronly: return "자동차전용도로회피"
    }
  }
}

// MARK: - 미리 정의된 목적지들
public struct PredefinedDestinations {
  public static let gangnamStation = Destination(
    name: "강남역",
    coordinate: CLLocationCoordinate2D(latitude: 37.497942, longitude: 127.027621),
    address: "서울특별시 강남구 강남대로 지하 396"
  )

  public static let hongikUniversity = Destination(
    name: "홍대입구역",
    coordinate: CLLocationCoordinate2D(latitude: 37.556785, longitude: 126.923011),
    address: "서울특별시 마포구 양화로 지하 188"
  )

  public static let myeongdong = Destination(
    name: "명동역",
    coordinate: CLLocationCoordinate2D(latitude: 37.560281, longitude: 126.986611),
    address: "서울특별시 중구 명동2가"
  )

  public static let itaewon = Destination(
    name: "이태원역",
    coordinate: CLLocationCoordinate2D(latitude: 37.534567, longitude: 126.994668),
    address: "서울특별시 용산구 이태원로 지하 177"
  )
}