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
  let name, category, address: String
  let distanceToStation, timeToStation, stayableMinutes: Int
  let stationLat, stationLon: Double
  let leaveTime: String
  let imageURL: [String]
  let weekday, weekend: [String]
  let phoneNumber: String

  enum CodingKeys: String, CodingKey {
    case name, category, address, distanceToStation, timeToStation, stayableMinutes, stationLat, stationLon, leaveTime
    case imageURL = "imageUrl"
    case weekday, weekend, phoneNumber
  }
}

