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
      placeId: placeId,
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceFromStation: distanceFromStation,
      walkTimeFromStation: walkTimeFromStation,
      stayableMinutes: stayableMinutes,
      visitable: visitable,
      stationLatitude: stationLatitude,
      stationLongitude: stationLongitude,
      leaveTime: leaveTime,
      images: images,
      useTime: useTime,
      spendTime: spendTime,
      useFee: useFee,
      discountInfo: discountInfo,
      accomCountCulture: accomCountCulture,
      parkingCulture: parkingCulture,
      placeType: placeType
    )
  }
}
