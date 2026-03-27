//
//  StationRowModel.swift
//  Home
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation
import Entity

public struct StationRowModel: Identifiable, Equatable, Hashable {
  public let id: String
  public let favoriteID: Int?
  public let station: Station?
  public let stationID: Int
  public let stationName: String
  public let badges: [String]
  public let lat: Double?
  public let lng: Double?
  public let distanceText: String?
  public let isFavorite: Bool

  public init(
    id: String,
    favoriteID: Int? = nil,
    station: Station?,
    stationID: Int,
    stationName: String,
    badges: [String],
    lat: Double? = nil,
    lng: Double? = nil,
    distanceText: String?,
    isFavorite: Bool
  ) {
    self.id = id
    self.favoriteID = favoriteID
    self.station = station
    self.stationID = stationID
    self.stationName = stationName
    self.badges = badges
    self.lat = lat
    self.lng = lng
    self.distanceText = distanceText
    self.isFavorite = isFavorite
  }
}
