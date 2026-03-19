//
//  TermsRowView.swif

//  Auth
//
//  Created by Wonji Suh  on 3/20/26.
//

import Foundation
import SwiftUI

import DesignSystem

public struct TermsRowView: View {
  private let title: String
  private let isOn: Bool
  private let action: () -> Void
  private let onArrowTap: () -> Void

  public init(
    title: String,
    isOn: Bool,
    action: @escaping () -> Void,
    onArrowTap: @escaping () -> Void,
  ) {
    self.title = title
    self.isOn = isOn
    self.action = action
    self.onArrowTap = onArrowTap
  }

  public var body: some View {
    HStack(spacing: .zero) {
      Button(action: action){
        HStack(spacing: 12) {
          Image(asset: isOn ? .check: .noCheck)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .onTapGesture(perform: action)

          Text(title)
            .pretendardCustomFont(textStyle: .titleRegular)
            .foregroundStyle(.gray900)
        }
      }

      Spacer()

      Button(action: onArrowTap){
        Image(asset: .arrowRight)
          .resizable()
          .scaledToFit()
          .frame(width: 8, height: 10)
      }
    }
  }
}
