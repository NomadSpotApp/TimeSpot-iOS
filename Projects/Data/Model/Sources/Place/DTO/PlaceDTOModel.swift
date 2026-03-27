//
//  PlaceDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation


public typealias PlaceDTOModel = BaseResponseDTO<[PlaceResponseDTOModel]>

// MARK: - Datum
public struct PlaceResponseDTOModel: Decodable, Equatable {
  let googlePlaceID, category: String
  let lat, lon: Double
  let stayableMinutes: Int
  let name, address: String

  enum CodingKeys: String, CodingKey {
    case googlePlaceID = "googlePlaceId"
    case category, lat, lon, stayableMinutes, name, address
  }
}
