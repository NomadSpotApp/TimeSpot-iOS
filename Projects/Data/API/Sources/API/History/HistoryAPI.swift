//
//  HistoryAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/26/26.
//
import Foundation

public enum HistoryAPI {
  case myHistory
  case startHistory
  case endHistory(historyId: Int)

  public var description: String {
    switch self {
      case .myHistory:
        return ""

      case .startHistory:
        return ""

      case .endHistory(let historyId):
        return "\(historyId)"
    }
  }
}

