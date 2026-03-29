//
//  NotificationSettingSkeletonView.swift
//  Profile
//

import SwiftUI

import DesignSystem
import Entity

public struct NotificationSettingSkeletonView: View {
  public init() {}

  public var body: some View {
    LazyVStack(spacing: 0) {
      ForEach(0..<NotificationOption.allCases.count, id: \.self) { index in
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 6)
            .fill(.gray300)
            .frame(width: index == 0 ? 68 : 96, height: 18)
            .notificationSettingSkeletonShimmer()

          Spacer()

          Circle()
            .fill(.gray300)
            .frame(width: 24, height: 24)
            .notificationSettingSkeletonShimmer()
        }
        .frame(height: 58)
        .padding(.horizontal, 20)

        if index != NotificationOption.allCases.count - 1 {
          Rectangle()
            .fill(.enableColor)
            .frame(height: 1)
            .padding(.horizontal, 14)
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(.gray200)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 24)
        .stroke(.enableColor, lineWidth: 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 24))
  }
}

private extension View {
  func notificationSettingSkeletonShimmer() -> some View {
    modifier(NotificationSettingSkeletonShimmerModifier())
  }
}

private struct NotificationSettingSkeletonShimmerModifier: ViewModifier {
  @State private var isAnimating = false

  func body(content: Content) -> some View {
    content
      .overlay {
        LinearGradient(
          colors: [
            .white.opacity(0),
            .white.opacity(0.45),
            .white.opacity(0)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .rotationEffect(.degrees(20))
        .offset(x: isAnimating ? 180 : -180)
        .mask(content)
      }
      .onAppear {
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) {
          isAnimating = true
        }
      }
  }
}
