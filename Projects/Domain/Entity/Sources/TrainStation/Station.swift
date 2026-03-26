//
//  Station.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public enum Station: String, CaseIterable, Equatable, Hashable, Identifiable {
  case seoul
  case yongsan
  case busan
  case dongdaegu
  case daejeon

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .seoul:
      return "서울"
    case .yongsan:
      return "용산"
    case .busan:
      return "부산"
    case .dongdaegu:
      return "동대구"
    case .daejeon:
      return "대전"
    }
  }

  public var homeTitle: String {
    switch self {
    case .seoul:
      return "SEOUL"
    case .yongsan:
      return "YONGSAN"
    case .busan:
      return "BUSAN"
    case .dongdaegu:
      return "DONGDAEGU"
    case .daejeon:
      return "DAEJEON"
    }
  }
}
