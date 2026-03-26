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

  public init(
    favoriteStations: [StationSummaryResponseDTO],
    nearbyStations: [StationSummaryResponseDTO],
    stations: StationPageResponseDTO
  ) {
    self.favoriteStations = favoriteStations
    self.nearbyStations = nearbyStations
    self.stations = stations
  }
}

public struct StationSummaryResponseDTO: Decodable, Equatable {
  public let stationID: Int
  public let name: String
  public let lines: [String]

  enum CodingKeys: String, CodingKey {
    case stationID = "stationId"
    case name
    case lines
  }

  public init(
    stationID: Int,
    name: String,
    lines: [String]
  ) {
    self.stationID = stationID
    self.name = name
    self.lines = lines
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
}
