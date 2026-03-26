//
//  StationAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public enum StationAPI {
  case allStation
  case favoriteStation
  case addFavoriteStation
  case deleteFavoriteStation(deleteStationId: Int)

  public var description: String {
    switch self {
      case .allStation:
        return ""
      case .favoriteStation:
        return ""
      case .addFavoriteStation:
        return ""
      case .deleteFavoriteStation(let deleteStationId):
        return "/\(deleteStationId)"
    }
  }
}
