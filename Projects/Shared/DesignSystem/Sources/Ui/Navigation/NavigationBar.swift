//
//  NavigationBar.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 3/25/26.
//

import SwiftUI

public struct CustomNavigationBackBar: View {
  private var buttonAction: () -> Void = { }
  private var title: String

  public init(
    buttonAction: @escaping () -> Void,
    title: String
  ) {
    self.buttonAction = buttonAction
    self.title = title
  }

  public var body: some View {
    ZStack {
      if !title.isEmpty {
        Text(title)
          .pretendardCustomFont(textStyle: .titleBold)
          .foregroundStyle(.staticBlack)
      }

      HStack {
        Image(asset: .leftArrow)
          .resizable()
          .scaledToFit()
          .frame(width: 48, height: 48)
          .contentShape(Rectangle())
          .onTapGesture {
            buttonAction()
          }

        Spacer()
      }
    }
  }
}
