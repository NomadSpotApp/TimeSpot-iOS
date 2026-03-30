//
//  PlaceAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation

public enum PlaceAPI {
  case fetchPlace
  case detailPlace(placeId: Int)

  public var description: String {
    switch self {
      case .fetchPlace:
        return ""
      case .detailPlace(let placeId):
        return "/\(placeId)"
    }
  }
}
