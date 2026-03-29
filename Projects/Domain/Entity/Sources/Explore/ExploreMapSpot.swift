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
  public let hasDetail: Bool
  public let imageURL: String?
  public let badgeText: String
  public let subtitle: String
  public let statusText: String
  public let closingText: String
  public let distanceText: String
  public let walkTimeText: String
  public let address: String

  public init(
    id: String,
    name: String,
    category: ExploreCategory,
    coordinate: CLLocationCoordinate2D,
    hasDetail: Bool = false,
    imageURL: String? = nil,
    badgeText: String,
    subtitle: String,
    statusText: String,
    closingText: String,
    distanceText: String,
    walkTimeText: String,
    address: String
  ) {
    self.id = id
    self.name = name
    self.category = category
    self.coordinate = coordinate
    self.hasDetail = hasDetail
    self.imageURL = imageURL
    self.badgeText = badgeText
    self.subtitle = subtitle
    self.statusText = statusText
    self.closingText = closingText
    self.distanceText = distanceText
    self.walkTimeText = walkTimeText
    self.address = address
  }
}

extension ExploreMapSpot: Equatable {
  public static func == (lhs: ExploreMapSpot, rhs: ExploreMapSpot) -> Bool {
    lhs.id == rhs.id
    && lhs.name == rhs.name
    && lhs.category == rhs.category
    && lhs.coordinate.latitude == rhs.coordinate.latitude
    && lhs.coordinate.longitude == rhs.coordinate.longitude
    && lhs.hasDetail == rhs.hasDetail
    && lhs.imageURL == rhs.imageURL
    && lhs.badgeText == rhs.badgeText
    && lhs.subtitle == rhs.subtitle
    && lhs.statusText == rhs.statusText
    && lhs.closingText == rhs.closingText
    && lhs.distanceText == rhs.distanceText
    && lhs.walkTimeText == rhs.walkTimeText
    && lhs.address == rhs.address
  }
}

extension ExploreMapSpot: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(category)
    hasher.combine(coordinate.latitude)
    hasher.combine(coordinate.longitude)
    hasher.combine(hasDetail)
    hasher.combine(imageURL)
    hasher.combine(badgeText)
    hasher.combine(subtitle)
    hasher.combine(statusText)
    hasher.combine(closingText)
    hasher.combine(distanceText)
    hasher.combine(walkTimeText)
    hasher.combine(address)
  }
}

public struct ExploreSpotPageEntity: Equatable {
  public let spots: [ExploreMapSpot]
  public let currentPage: Int
  public let hasNextPage: Bool

  public init(
    spots: [ExploreMapSpot],
    currentPage: Int,
    hasNextPage: Bool
  ) {
    self.spots = spots
    self.currentPage = currentPage
    self.hasNextPage = hasNextPage
  }
}
