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
  public let imageURL: String?
  public let stayableMinutes: Int?
  public let isOpen: Bool?
  public let closingTime: String?

  enum CodingKeys: String, CodingKey {
    case placeID = "placeId"
    case category, lat, lon, name, address, imageURL = "imageUrl", stayableMinutes, isOpen, closingTime
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

  enum CodingKeys: String, CodingKey {
    case pageable, last, numberOfElements, first, size, content, number, sort, empty
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.pageable = try container.decodeIfPresent(PlacePageableResponseDTO.self, forKey: .pageable) ?? .init()
    self.last = try container.decodeIfPresent(Bool.self, forKey: .last) ?? false
    self.numberOfElements = try container.decodeIfPresent(Int.self, forKey: .numberOfElements) ?? 0
    self.first = try container.decodeIfPresent(Bool.self, forKey: .first) ?? true
    self.size = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
    self.content = try container.decodeIfPresent([PlaceResponseDTOModel].self, forKey: .content) ?? []
    self.number = try container.decodeIfPresent(Int.self, forKey: .number) ?? 0
    self.sort = try container.decodeIfPresent(PlaceSortResponseDTO.self, forKey: .sort) ?? .init()
    self.empty = try container.decodeIfPresent(Bool.self, forKey: .empty) ?? self.content.isEmpty
  }
}

public struct PlacePageableResponseDTO: Decodable, Equatable {
  public let unpaged: Bool
  public let paged: Bool
  public let pageNumber: Int
  public let pageSize: Int
  public let offset: Int
  public let sort: PlaceSortResponseDTO

  enum CodingKeys: String, CodingKey {
    case unpaged, paged, pageNumber, pageSize, offset, sort
  }

  public init(
    unpaged: Bool = false,
    paged: Bool = true,
    pageNumber: Int = 0,
    pageSize: Int = 10,
    offset: Int = 0,
    sort: PlaceSortResponseDTO = .init()
  ) {
    self.unpaged = unpaged
    self.paged = paged
    self.pageNumber = pageNumber
    self.pageSize = pageSize
    self.offset = offset
    self.sort = sort
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.unpaged = try container.decodeIfPresent(Bool.self, forKey: .unpaged) ?? false
    self.paged = try container.decodeIfPresent(Bool.self, forKey: .paged) ?? true
    self.pageNumber = try container.decodeIfPresent(Int.self, forKey: .pageNumber) ?? 0
    self.pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize) ?? 10
    self.offset = try container.decodeIfPresent(Int.self, forKey: .offset) ?? 0
    self.sort = try container.decodeIfPresent(PlaceSortResponseDTO.self, forKey: .sort) ?? .init()
  }
}

public struct PlaceSortResponseDTO: Decodable, Equatable {
  public let unsorted: Bool
  public let sorted: Bool
  public let empty: Bool

  public init(
    unsorted: Bool = true,
    sorted: Bool = false,
    empty: Bool = true
  ) {
    self.unsorted = unsorted
    self.sorted = sorted
    self.empty = empty
  }

  enum CodingKeys: String, CodingKey {
    case unsorted, sorted, empty
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.unsorted = try container.decodeIfPresent(Bool.self, forKey: .unsorted) ?? true
    self.sorted = try container.decodeIfPresent(Bool.self, forKey: .sorted) ?? false
    self.empty = try container.decodeIfPresent(Bool.self, forKey: .empty) ?? true
  }
}
