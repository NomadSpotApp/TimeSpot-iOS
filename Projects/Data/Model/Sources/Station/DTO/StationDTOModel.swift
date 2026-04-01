//
//  StationDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public typealias StationDTOModel = BaseResponseDTO<StationListResponseDTO>

public struct StationListResponseDTO: Decodable, Equatable {
  public let favoriteStations: [StationSummaryResponseDTO]
  public let nearbyStations: [StationSummaryResponseDTO]
  public let stations: StationPageResponseDTO

  enum CodingKeys: String, CodingKey {
    case favoriteStations
    case nearbyStations
    case stations
  }

  public init(
    favoriteStations: [StationSummaryResponseDTO],
    nearbyStations: [StationSummaryResponseDTO],
    stations: StationPageResponseDTO
  ) {
    self.favoriteStations = favoriteStations
    self.nearbyStations = nearbyStations
    self.stations = stations
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.favoriteStations = (try? container.decode([StationSummaryResponseDTO].self, forKey: .favoriteStations)) ?? []
    self.nearbyStations = (try? container.decode([StationSummaryResponseDTO].self, forKey: .nearbyStations)) ?? []
    self.stations = try container.decode(StationPageResponseDTO.self, forKey: .stations)
  }
}

public struct StationSummaryResponseDTO: Decodable, Equatable {
  public let favoriteID: Int?
  public let stationID: Int
  public let name: String
  public let lines: [String]
  public let lat: Double?
  public let lng: Double?

  enum CodingKeys: String, CodingKey {
    case favoriteID = "favoriteId"
    case stationID = "stationId"
    case name
    case lines
    case lat
    case lng
  }

  public init(
    favoriteID: Int? = nil,
    stationID: Int,
    name: String,
    lines: [String],
    lat: Double? = nil,
    lng: Double? = nil
  ) {
    self.favoriteID = favoriteID
    self.stationID = stationID
    self.name = name
    self.lines = lines
    self.lat = lat
    self.lng = lng
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.favoriteID = try container.decodeIfPresent(Int.self, forKey: .favoriteID)
    self.stationID = try container.decode(Int.self, forKey: .stationID)
    self.name = try container.decode(String.self, forKey: .name)
    self.lines = try container.decode([String].self, forKey: .lines)
    self.lat = try container.decodeIfPresent(Double.self, forKey: .lat)
    self.lng = try container.decodeIfPresent(Double.self, forKey: .lng)
  }
}

public struct StationPageResponseDTO: Decodable, Equatable {
  public let content: [StationSummaryResponseDTO]
  public let totalElements: Int
  public let totalPages: Int
  public let last: Bool
  public let first: Bool
  public let numberOfElements: Int
  public let size: Int
  public let number: Int
  public let empty: Bool

  enum CodingKeys: String, CodingKey {
    case content
    case totalElements
    case totalPages
    case last
    case first
    case numberOfElements
    case size
    case number
    case empty
    case hasNext
  }

  public init(
    content: [StationSummaryResponseDTO],
    totalElements: Int,
    totalPages: Int,
    last: Bool,
    first: Bool,
    numberOfElements: Int,
    size: Int,
    number: Int,
    empty: Bool
  ) {
    self.content = content
    self.totalElements = totalElements
    self.totalPages = totalPages
    self.last = last
    self.first = first
    self.numberOfElements = numberOfElements
    self.size = size
    self.number = number
    self.empty = empty
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let content = try container.decode([StationSummaryResponseDTO].self, forKey: .content)
    let totalElements = try container.decode(Int.self, forKey: .totalElements)
    let totalPages = try container.decode(Int.self, forKey: .totalPages)
    let size = try container.decode(Int.self, forKey: .size)
    let number = try container.decode(Int.self, forKey: .number)

    let hasNext = try container.decodeIfPresent(Bool.self, forKey: .hasNext) ?? false
    let first = try container.decodeIfPresent(Bool.self, forKey: .first) ?? (number == 0)
    let last = try container.decodeIfPresent(Bool.self, forKey: .last) ?? !hasNext
    let numberOfElements = try container.decodeIfPresent(Int.self, forKey: .numberOfElements) ?? content.count
    let empty = try container.decodeIfPresent(Bool.self, forKey: .empty) ?? content.isEmpty

    self.init(
      content: content,
      totalElements: totalElements,
      totalPages: totalPages,
      last: last,
      first: first,
      numberOfElements: numberOfElements,
      size: size,
      number: number,
      empty: empty
    )
  }
}
