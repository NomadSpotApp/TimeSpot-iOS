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

  public var apiType: String {
    switch self {
    case .none:
      return "NONE"
    case .departureTime:
      return "DEPARTURE_TIME"
    case .fiveMinutesBefore:
      return "DEPARTURE_5_MIN_BEFORE"
    case .tenMinutesBefore:
      return "DEPARTURE_10_MIN_BEFORE"
    case .fifteenMinutesBefore:
      return "DEPARTURE_15_MIN_BEFORE"
    }
  }

  public init?(apiType: String) {
    switch apiType.uppercased() {
    case "DEPARTURE_TIME":
      self = .departureTime
    case "DEPARTURE_5_MIN_BEFORE":
      self = .fiveMinutesBefore
    case "DEPARTURE_10_MIN_BEFORE":
      self = .tenMinutesBefore
    case "DEPARTURE_15_MIN_BEFORE":
      self = .fifteenMinutesBefore
    case "NONE":
      self = .none
    default:
      return nil
    }
  }
}
