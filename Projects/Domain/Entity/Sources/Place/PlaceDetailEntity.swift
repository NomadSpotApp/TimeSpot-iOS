//
//  PlaceDetailEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation

public struct PlaceDetailEntity: Equatable, Hashable {
  public let placeId: String
  public let name: String
  public let category: String
  public let address: String
  public let latitude: Double
  public let longitude: Double
  public let distanceFromStation: Int
  public let walkTimeFromStation: Int
  public let stayableMinutes: Int
  public let visitable: Bool
  public let stationLatitude: Double
  public let stationLongitude: Double
  public let leaveTime: String
  public let images: [String]
  public let useTime: String?
  public let spendTime: String?
  public let useFee: String?
  public let discountInfo: String?
  public let accomCountCulture: String?
  public let parkingCulture: String?
  public let placeType: String

  public init(
    placeId: String,
    name: String,
    category: String,
    address: String,
    latitude: Double,
    longitude: Double,
    distanceFromStation: Int,
    walkTimeFromStation: Int,
    stayableMinutes: Int,
    visitable: Bool,
    stationLatitude: Double,
    stationLongitude: Double,
    leaveTime: String,
    images: [String],
    useTime: String? = nil,
    spendTime: String? = nil,
    useFee: String? = nil,
    discountInfo: String? = nil,
    accomCountCulture: String? = nil,
    parkingCulture: String? = nil,
    placeType: String
  ) {
    self.placeId = placeId
    self.name = name
    self.category = category
    self.address = address
    self.latitude = latitude
    self.longitude = longitude
    self.distanceFromStation = distanceFromStation
    self.walkTimeFromStation = walkTimeFromStation
    self.stayableMinutes = stayableMinutes
    self.visitable = visitable
    self.stationLatitude = stationLatitude
    self.stationLongitude = stationLongitude
    self.leaveTime = leaveTime
    self.images = images
    self.useTime = useTime
    self.spendTime = spendTime
    self.useFee = useFee
    self.discountInfo = discountInfo
    self.accomCountCulture = accomCountCulture
    self.parkingCulture = parkingCulture
    self.placeType = placeType
  }
}
