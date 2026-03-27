//
//  PlaceDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation


public typealias PlaceDTOModel = BaseResponseDTO<[PlaceResponseDTOModel]>
public typealias PlaceSearchDTOModel = BaseResponseDTO<PlaceSearchPageResponseDTO>

// MARK: - Datum
public struct PlaceResponseDTOModel: Decodable, Equatable {
  public let placeID: Int
  public let category: String
  public let lat: Double
  public let lon: Double
  public let name: String?
  public let address: String?
  public let stayableMinutes: Int?
  public let isOpen: Bool?
  public let closingTime: String?

  enum CodingKeys: String, CodingKey {
    case placeID = "placeId"
    case category, lat, lon, name, address, stayableMinutes, isOpen, closingTime
  }
}

public struct PlaceSearchPageResponseDTO: Decodable, Equatable {
  public let pageable: PlacePageableResponseDTO
  public let last: Bool
  public let numberOfElements: Int
  public let first: Bool
  public let size: Int
  public let content: [PlaceResponseDTOModel]
  public let number: Int
  public let sort: PlaceSortResponseDTO
  public let empty: Bool
}

public struct PlacePageableResponseDTO: Decodable, Equatable {
  public let unpaged: Bool
  public let paged: Bool
  public let pageNumber: Int
  public let pageSize: Int
  public let offset: Int
  public let sort: PlaceSortResponseDTO
}

public struct PlaceSortResponseDTO: Decodable, Equatable {
  public let unsorted: Bool
  public let sorted: Bool
  public let empty: Bool
}
