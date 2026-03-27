//
//  StationAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public enum StationAPI {
  case allStation
  case addFavoriteStation(stationID: Int)
  case deleteFavoriteStation(stationID: Int)

  public var description: String {
    switch self {
      case .allStation:
        return ""
      case .addFavoriteStation(let stationID):
        return "/favorites/\(stationID)"
      case .deleteFavoriteStation(let stationID):
        return "/favorites/\(stationID)"
    }
  }
}
