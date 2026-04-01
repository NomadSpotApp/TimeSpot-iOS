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
  public let placeId: String
  public let name: String?
  public let category: String
  public let address: String?
  public let latitude: Double
  public let longitude: Double
  public let distanceFromUser: Double?
  public let distanceFromStation: Double?
  public let walkTimeFromStation: Int?
  public let stayableMinutes: Int?
  public let visitable: Bool
  public let imageUrl: String?
  public let isOpen: Bool?
  public let closingTime: String?

  enum CodingKeys: String, CodingKey {
    case placeId, name, category, address
    case latitude, longitude, lat, lon
    case distanceFromUser, distanceFromStation, walkTimeFromStation
    case stayableMinutes, visitable, imageUrl, isOpen, closingTime
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.placeId = try container.decode(String.self, forKey: .placeId)
    self.name = try container.decodeIfPresent(String.self, forKey: .name)
    self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
    self.address = try container.decodeIfPresent(String.self, forKey: .address)
    if let latitudeValue = try container.decodeIfPresent(Double.self, forKey: .latitude) {
      self.latitude = latitudeValue
    } else if let latValue = try container.decodeIfPresent(Double.self, forKey: .lat) {
      self.latitude = latValue
    } else {
      self.latitude = 0
    }
    if let longitudeValue = try container.decodeIfPresent(Double.self, forKey: .longitude) {
      self.longitude = longitudeValue
    } else if let lonValue = try container.decodeIfPresent(Double.self, forKey: .lon) {
      self.longitude = lonValue
    } else {
      self.longitude = 0
    }
    self.distanceFromUser = try container.decodeIfPresent(Double.self, forKey: .distanceFromUser)
    self.distanceFromStation = try container.decodeIfPresent(Double.self, forKey: .distanceFromStation)
    self.walkTimeFromStation = try container.decodeIfPresent(Int.self, forKey: .walkTimeFromStation)
    self.stayableMinutes = try container.decodeIfPresent(Int.self, forKey: .stayableMinutes)
    self.visitable = try container.decodeIfPresent(Bool.self, forKey: .visitable) ?? false
    self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
    self.isOpen = try container.decodeIfPresent(Bool.self, forKey: .isOpen)
    self.closingTime = try container.decodeIfPresent(String.self, forKey: .closingTime)
  }
}

public struct PlaceSearchPageResponseDTO: Decodable, Equatable {
  public let content: [PlaceResponseDTOModel]
  public let number: Int
  public let size: Int
  public let hasNext: Bool
  public let totalPages: Int
  public let totalElements: Int
  public let sort: PlaceSortResponseDTO

  enum CodingKeys: String, CodingKey {
    case content, number, size, hasNext, totalPages, totalElements, sort
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.content = try container.decodeIfPresent([PlaceResponseDTOModel].self, forKey: .content) ?? []
    self.number = try container.decodeIfPresent(Int.self, forKey: .number) ?? 0
    self.size = try container.decodeIfPresent(Int.self, forKey: .size) ?? 10
    self.hasNext = try container.decodeIfPresent(Bool.self, forKey: .hasNext) ?? false
    self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 0
    self.totalElements = try container.decodeIfPresent(Int.self, forKey: .totalElements) ?? 0
    self.sort = try container.decodeIfPresent(PlaceSortResponseDTO.self, forKey: .sort) ?? .init()
  }
}

public struct PlaceSortResponseDTO: Decodable, Equatable {
  public let empty: Bool
  public let sorted: Bool
  public let unsorted: Bool

  public init(
    empty: Bool = true,
    sorted: Bool = false,
    unsorted: Bool = true
  ) {
    self.empty = empty
    self.sorted = sorted
    self.unsorted = unsorted
  }

  enum CodingKeys: String, CodingKey {
    case empty, sorted, unsorted
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.empty = try container.decodeIfPresent(Bool.self, forKey: .empty) ?? true
    self.sorted = try container.decodeIfPresent(Bool.self, forKey: .sorted) ?? false
    self.unsorted = try container.decodeIfPresent(Bool.self, forKey: .unsorted) ?? true
  }
}
