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
  private let totalSteps: Int

  public init(activeStep: Int, totalSteps: Int = 4) {
    self.activeStep = activeStep
    self.totalSteps = totalSteps
  }

  public var body: some View {
    HStack(alignment: .center, spacing: 4) {
      ForEach(1...totalSteps, id: \.self) { step in
        Capsule()
          .fill(step <= activeStep ? Color.orange800 : Color.enableColor)
          .frame(maxWidth: 48, minHeight: 4, maxHeight: 4)
      }
    }
  }
}
