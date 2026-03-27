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
