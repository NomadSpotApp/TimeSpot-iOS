//
//  StationRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct StationRequest: Encodable, Equatable {
  public let lat: Double
  public let lng: Double
  public let page: Int
  public let size: Int
  public let sort: String

  public init(
    lat: Double,
    lng: Double,
    page: Int = 1,
    size: Int = 10,
    sort: String = "stationName,ASC"
  ) {
    self.lat = lat
    self.lng = lng
    self.page = max(page, 1)
    self.size = max(size, 10)
    self.sort = sort
  }
}

public struct FavoriteStationRequest: Encodable, Equatable {
  public let page: Int
  public let size: Int
  public let sort: String

  public init(
    page: Int = 1,
    size: Int = 10,
    sort: String = "stationName,ASC"
  ) {
    self.page = max(page, 1)
    self.size = max(size, 10)
    self.sort = sort
  }
}

public struct AddFavoriteStationRequest: Encodable, Equatable {
  public let stationID: Int

  enum CodingKeys: String, CodingKey {
    case stationID = "stationId"
  }

  public init(stationID: Int) {
    self.stationID = stationID
  }
}
