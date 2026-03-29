//
//  CameraControlResult.swift
//  Entity
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation

public struct CameraControlResult: Equatable {
  public let shouldUpdateTrigger: Bool
  public let newTrigger: Int
  public let shouldClearSpot: Bool
  public let shouldResetFlag: Bool
  public let shouldDismissCard: Bool

  public init(
    shouldUpdateTrigger: Bool = false,
    newTrigger: Int = 0,
    shouldClearSpot: Bool = false,
    shouldResetFlag: Bool = false,
    shouldDismissCard: Bool = false
  ) {
    self.shouldUpdateTrigger = shouldUpdateTrigger
    self.newTrigger = newTrigger
    self.shouldClearSpot = shouldClearSpot
    self.shouldResetFlag = shouldResetFlag
    self.shouldDismissCard = shouldDismissCard
  }
}