//
//  UIScreen+.swift
//  Utill
//
//  Created by Wonji Suh on 3/30/26.
//

import UIKit

public extension UIScreen {
  // MARK: - Card UI Utils
  static var cardTravelDistance: CGFloat {
    main.bounds.width - 8
  }

  static var cardSwipeThreshold: CGFloat {
    (main.bounds.width - 32) / 2
  }
}