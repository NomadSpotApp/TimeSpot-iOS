//
//  ExploreCategory.swift
//  Entity
//
//  Created by Wonji Suh on 2026-03-27.
//

import Foundation

public enum ExploreCategory: String, CaseIterable, Equatable, Sendable {
  case all
  case cafe
  case restaurant
  case activity
  case shopping
  case etc

  public var title: String {
    switch self {
    case .all:
      return "전체"
    case .cafe:
      return "카페"
    case .restaurant:
      return "음식점"
    case .activity:
      return "액티비티"
    case .shopping:
      return "쇼핑"
    case .etc:
      return "기타"
    }
  }
}
