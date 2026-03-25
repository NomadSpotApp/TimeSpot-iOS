//
//  NotificationOption.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public enum NotificationOption: String, CaseIterable, Equatable, Hashable, Identifiable {
  case none
  case departureTime
  case fiveMinutesBefore
  case tenMinutesBefore
  case fifteenMinutesBefore

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .none:
      return "설정 하지 않음"
    case .departureTime:
      return "출발 시간"
    case .fiveMinutesBefore:
      return "출발 5분 전"
    case .tenMinutesBefore:
      return "출발 10분 전"
    case .fifteenMinutesBefore:
      return "출발 15분 전"
    }
  }
}
