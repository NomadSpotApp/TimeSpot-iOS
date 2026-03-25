//
//  TravelHistorySort.swift
//  Entity
//
//  Created by Wonji Suh on 3/25/26.
//

import Foundation

public enum TravelHistorySort: String, CaseIterable, Equatable, Hashable {
  case oldest
  case recent

  public var title: String {
    switch self {
      case .recent:
        return "최근 방문한 순"
      case .oldest:
        return "오래된 순"
    }
  }
}
