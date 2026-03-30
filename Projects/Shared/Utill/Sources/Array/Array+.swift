//
//  Array+.swift
//  Utill
//
//  Created by Wonji Suh on 3/30/26.
//

import Foundation

public extension Array where Element: Hashable {
  // MARK: - Spot Utils
  func hasUnresolvedSpots<T>(keyPath: KeyPath<Element, T>) -> Bool where T: Hashable {
    return contains { element in
      let value = element[keyPath: keyPath]
      // 타입별로 "미해결" 상태를 판단
      if let boolValue = value as? Bool {
        return !boolValue // hasDetail이 false인 경우
      }
      if let stringValue = value as? String {
        return stringValue.isEmpty // 문자열이 비어있는 경우
      }
      return false
    }
  }
}

// ExploreMapSpot 전용 확장
import Entity

public extension Array where Element == ExploreMapSpot {
  var hasUnresolvedBaseSpots: Bool {
    return contains { !$0.hasDetail }
  }
}