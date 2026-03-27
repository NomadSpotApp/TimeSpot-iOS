//
//  StationAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public enum StationAPI {
  case allStation
  case addFavoriteStation
  case deleteFavoriteStation(favoriteID: Int)

  public var description: String {
    switch self {
      case .allStation:
        return ""
      case .addFavoriteStation:
        return "/favorites"
      case .deleteFavoriteStation(let favoriteID):
        return "/favorites/\(favoriteID)"
    }
  }
}
