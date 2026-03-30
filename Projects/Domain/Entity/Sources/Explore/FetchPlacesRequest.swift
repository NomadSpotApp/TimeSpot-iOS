//
//  FetchPlacesRequest.swift
//  Entity
//
//  Created by Wonji Suh  on 3/30/26.
//

import Foundation

public struct FetchPlacesRequest: Equatable, Sendable {
  public let page: Int
  public let keyword: String
  public let category: ExploreCategory?
  public let markerLat: Double?
  public let markerLon: Double?
  public let append: Bool
  public let usedCurrentLocation: Bool

  public init(
    page: Int,
    keyword: String,
    category: ExploreCategory?,
    markerLat: Double?,
    markerLon: Double?,
    append: Bool,
    usedCurrentLocation: Bool
  ) {
    self.page = page
    self.keyword = keyword
    self.category = category
    self.markerLat = markerLat
    self.markerLon = markerLon
    self.append = append
    self.usedCurrentLocation = usedCurrentLocation
  }
}
