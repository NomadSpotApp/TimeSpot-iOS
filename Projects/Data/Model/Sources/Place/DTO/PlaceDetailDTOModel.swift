//
//  PlaceDetailDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation

public typealias PlaceDetailDTOModel = BaseResponseDTO<PlaceDetailDTOResponseModel>

// MARK: - DataClass
public struct PlaceDetailDTOResponseModel: Decodable, Equatable {
  let placeId: String
  let name, category, address: String
  let latitude, longitude: Double
  let distanceFromStation, walkTimeFromStation, stayableMinutes: Int
  let visitable: Bool
  let stationLatitude, stationLongitude: Double
  let leaveTime: String
  let images: [String]
  let useTime: String?
  let spendTime: String?
  let useFee: String?
  let discountInfo: String?
  let accomCountCulture: String?
  let parkingCulture: String?
  let placeType: String

  enum CodingKeys: String, CodingKey {
    case placeId, name, category, address, latitude, longitude
    case distanceFromStation, walkTimeFromStation, stayableMinutes, visitable
    case stationLatitude, stationLongitude, leaveTime, images
    case useTime, spendTime, useFee, discountInfo, accomCountCulture, parkingCulture, placeType
  }
}

