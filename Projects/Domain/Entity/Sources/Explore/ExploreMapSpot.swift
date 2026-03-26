//
//  ExploreMapSpot.swift
//  Entity
//
//  Created by wonji suh on 2026-03-27.
//

import Foundation
import CoreLocation

public struct ExploreMapSpot: Identifiable {
  public let id: String
  public let name: String
  public let category: ExploreCategory
  public let coordinate: CLLocationCoordinate2D
  public let badgeText: String
  public let subtitle: String
  public let statusText: String
  public let closingText: String
  public let distanceText: String
  public let walkTimeText: String

  public init(
    id: String,
    name: String,
    category: ExploreCategory,
    coordinate: CLLocationCoordinate2D,
    badgeText: String,
    subtitle: String,
    statusText: String,
    closingText: String,
    distanceText: String,
    walkTimeText: String
  ) {
    self.id = id
    self.name = name
    self.category = category
    self.coordinate = coordinate
    self.badgeText = badgeText
    self.subtitle = subtitle
    self.statusText = statusText
    self.closingText = closingText
    self.distanceText = distanceText
    self.walkTimeText = walkTimeText
  }

  public static let mockSpots: [ExploreMapSpot] = [
    .init(
      id: "cityhall-cafe-1",
      name: "시청 브루잉",
      category: .cafe,
      coordinate: CLLocationCoordinate2D(latitude: 37.5669, longitude: 126.9789),
      badgeText: "24분 체류 가능",
      subtitle: "카페",
      statusText: "영업 중",
      closingText: "21:00에 영업종료",
      distanceText: "180m",
      walkTimeText: "시청역에서 약 3분"
    ),
    .init(
      id: "cityhall-cafe-2",
      name: "덕수궁 카페",
      category: .cafe,
      coordinate: CLLocationCoordinate2D(latitude: 37.5658, longitude: 126.9758),
      badgeText: "19분 체류 가능",
      subtitle: "카페",
      statusText: "영업 중",
      closingText: "20:30에 영업종료",
      distanceText: "230m",
      walkTimeText: "시청역에서 약 4분"
    ),
    .init(
      id: "cityhall-food-1",
      name: "시청역 한식당",
      category: .restaurant,
      coordinate: CLLocationCoordinate2D(latitude: 37.5652, longitude: 126.9797),
      badgeText: "32분 체류 가능",
      subtitle: "음식점",
      statusText: "영업 중",
      closingText: "22:00에 영업종료",
      distanceText: "140m",
      walkTimeText: "시청역에서 약 2분"
    ),
    .init(
      id: "cityhall-food-2",
      name: "정동길 다이닝",
      category: .restaurant,
      coordinate: CLLocationCoordinate2D(latitude: 37.5674, longitude: 126.9739),
      badgeText: "28분 체류 가능",
      subtitle: "음식점",
      statusText: "영업 중",
      closingText: "21:30에 영업종료",
      distanceText: "310m",
      walkTimeText: "시청역에서 약 5분"
    ),
    .init(
      id: "cityhall-activity-1",
      name: "덕수궁 산책",
      category: .activity,
      coordinate: CLLocationCoordinate2D(latitude: 37.5659, longitude: 126.9751),
      badgeText: "41분 체류 가능",
      subtitle: "액티비티",
      statusText: "운영 중",
      closingText: "19:00에 입장마감",
      distanceText: "260m",
      walkTimeText: "시청역에서 약 4분"
    ),
    .init(
      id: "cityhall-activity-2",
      name: "서울광장 이벤트",
      category: .activity,
      coordinate: CLLocationCoordinate2D(latitude: 37.5663, longitude: 126.9779),
      badgeText: "17분 체류 가능",
      subtitle: "액티비티",
      statusText: "진행 중",
      closingText: "18:00에 종료",
      distanceText: "90m",
      walkTimeText: "시청역에서 약 1분"
    ),
    .init(
      id: "cityhall-etc-1",
      name: "시청 소품샵",
      category: .etc,
      coordinate: CLLocationCoordinate2D(latitude: 37.5677, longitude: 126.9808),
      badgeText: "26분 체류 가능",
      subtitle: "기타",
      statusText: "영업 중",
      closingText: "20:00에 영업종료",
      distanceText: "280m",
      walkTimeText: "시청역에서 약 4분"
    ),
    .init(
      id: "cityhall-etc-2",
      name: "서울 굿즈 스토어",
      category: .etc,
      coordinate: CLLocationCoordinate2D(latitude: 37.5648, longitude: 126.9770),
      badgeText: "22분 체류 가능",
      subtitle: "기타",
      statusText: "영업 중",
      closingText: "19:30에 영업종료",
      distanceText: "210m",
      walkTimeText: "시청역에서 약 3분"
    )
  ]
}

extension ExploreMapSpot: Equatable {
  public static func == (lhs: ExploreMapSpot, rhs: ExploreMapSpot) -> Bool {
    lhs.id == rhs.id
    && lhs.name == rhs.name
    && lhs.category == rhs.category
    && lhs.coordinate.latitude == rhs.coordinate.latitude
    && lhs.coordinate.longitude == rhs.coordinate.longitude
    && lhs.badgeText == rhs.badgeText
    && lhs.subtitle == rhs.subtitle
    && lhs.statusText == rhs.statusText
    && lhs.closingText == rhs.closingText
    && lhs.distanceText == rhs.distanceText
    && lhs.walkTimeText == rhs.walkTimeText
  }
}

extension ExploreMapSpot: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(category)
    hasher.combine(coordinate.latitude)
    hasher.combine(coordinate.longitude)
    hasher.combine(badgeText)
    hasher.combine(subtitle)
    hasher.combine(statusText)
    hasher.combine(closingText)
    hasher.combine(distanceText)
    hasher.combine(walkTimeText)
  }
}
