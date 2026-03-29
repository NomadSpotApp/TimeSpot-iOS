//
//  PlaceDetailEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation

public struct PlaceDetailEntity: Equatable, Hashable {
  public let name: String
  public let category: String
  public let address: String
  public let distanceToStation: Int
  public let timeToStation: Int
  public let stayableMinutes: Int
  public let stationLat: Double
  public let stationLon: Double
  public let leaveTime: String
  public let imageURL: [String]
  public let weekday: [String]
  public let weekend: [String]
  public let phoneNumber: String

  public init(
    name: String,
    category: String,
    address: String,
    distanceToStation: Int,
    timeToStation: Int,
    stayableMinutes: Int,
    stationLat: Double,
    stationLon: Double,
    leaveTime: String,
    imageURL: [String],
    weekday: [String],
    weekend: [String],
    phoneNumber: String
  ) {
    self.name = name
    self.category = category
    self.address = address
    self.distanceToStation = distanceToStation
    self.timeToStation = timeToStation
    self.stayableMinutes = stayableMinutes
    self.stationLat = stationLat
    self.stationLon = stationLon
    self.leaveTime = leaveTime
    self.imageURL = imageURL
    self.weekday = weekday
    self.weekend = weekend
    self.phoneNumber = phoneNumber
  }
}
