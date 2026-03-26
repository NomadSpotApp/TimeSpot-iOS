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
  case gangneung
  case cheongnyangri

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
    case .gangneung:
      return "강릉"
    case .cheongnyangri:
      return "청량리"
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
    case .gangneung:
      return "GANGNEUNG"
    case .cheongnyangri:
      return "CHEONGNYANGNI"
    }
  }

  public init?(displayName: String) {
    let normalized = displayName
      .replacingOccurrences(of: "역", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalized {
    case "서울":
      self = .seoul
    case "용산":
      self = .yongsan
    case "부산":
      self = .busan
    case "동대구":
      self = .dongdaegu
    case "대전":
      self = .daejeon
    case "강릉":
      self = .gangneung
    case "청량리":
      self = .cheongnyangri
    default:
      return nil
    }
  }
}
