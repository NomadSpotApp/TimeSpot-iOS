//
//  ToastType.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 12/29/25.
//

import SwiftUI

public enum ToastType: Equatable {
  case success(String)
  case error(String)
  case warning(String)
  case info(String)
  case loading(String)

  public var message: String {
    switch self {
      case .success(let message),
          .error(let message),
          .warning(let message),
          .info(let message),
          .loading(let message):
        return message
    }
  }

  public var backgroundColor: Color {
    switch self {
      case .success:
        return .gray800
      case .error:
        return .gray800
      case .warning:
        return .gray800
      case .info:
        return .gray800
      case .loading:
        return .gray800
    }
  }

  public var iconName: String? {
    switch self {
      case .success:
        return "warning"
      case .error:
        return "warning"
      case .warning:
        return "warning"
      case .info:
        return "warning"
      case .loading:
        return nil
    }
  }

  public var iconColor: Color {
    switch self {
      case .success:
        return .white
      case .error:
        return .red
      case .warning:
        return .red
      case .info:
        return .white
      case .loading:
        return .white
    }
  }
}
