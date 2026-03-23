//
//  ExternalMap.swift
//  Entity
//
//  Created by Wonji Suh  on 3/22/26.
//

import Foundation

public enum ExternalMapType: String, CaseIterable, Identifiable, Hashable, Equatable {
  case googleMap
  case naverMap
  case appleMap

  public var id: String { rawValue }

  public var description: String {
    switch self {
      case .appleMap:
        return "애플지도"

      case .googleMap:
        return "Google Maps"

      case .naverMap:
        return "네이버지도"
    }
  }

  public var type: String {
    switch self {
      case .googleMap:
        return "google"
      case .naverMap:
        return "naver"
      case .appleMap:
        return "apple"
    }
  }

  public var image: String {
    switch self {
      case .appleMap:
        return "appleMap"
      case .googleMap:
        return "goolgeMap"
      case .naverMap:
        return "naverMap"
    }
  }
}
