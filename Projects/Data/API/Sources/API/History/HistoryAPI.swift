//
//  HistoryAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/26/26.
//
import Foundation

public enum HistoryAPI: String, CaseIterable {
  case myHistory

  public var description: String {
    switch self {
      case .myHistory:
        return ""
    }
  }
}

