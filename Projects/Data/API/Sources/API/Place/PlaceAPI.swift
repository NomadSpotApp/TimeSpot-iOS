//
//  PlaceAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation

public enum PlaceAPI: String, CaseIterable {
  case fetchPlace

  public var description: String {
    switch self {
      case .fetchPlace:
        return ""
    }
  }
}
