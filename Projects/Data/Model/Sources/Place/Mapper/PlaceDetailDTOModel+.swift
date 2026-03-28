//
//  PlaceDetailDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/29/26.
//

import Foundation

import Entity

public extension PlaceDetailDTOResponseModel {
  func toDomain() -> PlaceDetailEntity {
    PlaceDetailEntity(
      name: name,
      category: category,
      address: address,
      distanceToStation: distanceToStation,
      timeToStation: timeToStation,
      stayableMinutes: stayableMinutes,
      stationLat: stationLat,
      stationLon: stationLon,
      leaveTime: leaveTime,
      imageURL: imageURL,
      weekday: weekday,
      weekend: weekend,
      phoneNumber: phoneNumber
    )
  }
}
