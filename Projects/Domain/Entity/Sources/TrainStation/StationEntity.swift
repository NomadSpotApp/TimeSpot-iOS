//
//  StationEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/30/26.
//

import Foundation

public struct StationEntity: Identifiable, Equatable, Hashable, Sendable {
  public let id: Int
  public let favoriteID: Int?
  public let station: Station?
  public let name: String
  public let badges: [String]
  public let latitude: Double?
  public let longitude: Double?
  public let isFavorite: Bool

  public init(
    id: Int,
    favoriteID: Int? = nil,
    station: Station?,
    name: String,
    badges: [String],
    latitude: Double? = nil,
    longitude: Double? = nil,
    isFavorite: Bool = false
  ) {
    self.id = id
    self.favoriteID = favoriteID
    self.station = station
    self.name = name
    self.badges = badges
    self.latitude = latitude
    self.longitude = longitude
    self.isFavorite = isFavorite
  }
}