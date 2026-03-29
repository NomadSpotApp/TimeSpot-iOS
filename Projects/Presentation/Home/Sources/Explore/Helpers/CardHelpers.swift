//
//  CardHelpers.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import SwiftUI

// MARK: - CardHelpers

public struct CardHelpers {

  // MARK: - Constants

  public static var cardTravelDistance: CGFloat {
    UIScreen.main.bounds.width - 8
  }

  public static var cardSwipeThreshold: CGFloat {
    (UIScreen.main.bounds.width - 32) / 2
  }
}