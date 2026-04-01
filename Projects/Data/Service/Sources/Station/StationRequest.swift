//
//  StationRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct StationRequest: Encodable, Equatable {
  public let userLat: Double
  public let userLon: Double
  public let page: Int
  public let size: Int
  public let sort: String
  public let radius: Int

  public init(
    userLat: Double,
    userLon: Double,
    page: Int = 1,
    size: Int = 10,
    sort: String = "stationName,ASC",
    radius: Int = 20000
  ) {
    self.userLat = userLat
    self.userLon = userLon
    self.page = max(page, 1)
    self.size = max(size, 10)
    self.sort = sort
    self.radius = radius
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
