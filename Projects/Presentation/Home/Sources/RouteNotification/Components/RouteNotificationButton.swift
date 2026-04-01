//
//  RouteNotificationButton.swift
//  Home
//
//  Created by Wonji Suh  on 4/1/26.
//

import SwiftUI
import DesignSystem

public struct RouteNotificationButton: View {
  private let title: String
  private let backgroundColor: Color
  private let foregroundColor: Color
  private let action: () -> Void

  public init(
    title: String,
    backgroundColor: Color,
    foregroundColor: Color,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.backgroundColor = backgroundColor
    self.foregroundColor = foregroundColor
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      Text(title)
        .pretendardCustomFont(textStyle: .bodyBold)
        .foregroundColor(foregroundColor)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(backgroundColor)
        .cornerRadius(28)
    }
  }
}
