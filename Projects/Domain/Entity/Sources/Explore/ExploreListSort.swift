//
//  ExploreListSort.swift
//  Entity
//
//  Created by Wonji Suh  on 3/30/26.
//

import Foundation

public enum ExploreListSort: String, CaseIterable, Equatable {
  case stationNearest = "distanceFromStation,ASC"
  case userNearest = "distanceFromUser,ASC"

  public var title: String {
    switch self {
    case .stationNearest:
      return "역에서 가까운 순"
    case .userNearest:
      return "현재 위치로부터 가까운 순"
    }
  }
}
