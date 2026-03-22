//
//  StepNavigationBar.swift
//  OnBoarding
//
//  Created by Wonji Suh  on 3/21/26.
//

import SwiftUI
import DesignSystem


public struct StepNavigationBar: View {
  private let activeStep: Int

  public init(activeStep: Int) {
    self.activeStep = activeStep
  }

  public var body: some View {
    HStack(alignment: .center, spacing: 4) {
      ForEach(1...4, id: \.self) { step in
        Rectangle()
          .foregroundColor(.clear)
          .frame(maxWidth: 48, minHeight: 4, maxHeight: 4)
          .background(step <= activeStep ? .orange800 : .enableColor)
          .clipShape(Capsule())
      }
    }
  }
}
