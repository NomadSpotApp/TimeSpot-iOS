//
//  TravelHistoryCardSkeletonView.swift
//  Profile
//
//  Created by Wonji Suh on 3/25/26.
//

import SwiftUI
import DesignSystem

public struct TravelHistoryCardSkeletonView: View {

  public init() {}

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Date skeleton
      RoundedRectangle(cornerRadius: 4)
        .fill(.gray300)
        .frame(width: 80, height: 12)
        .shimmerEffect()

      Spacer()
        .frame(height: 10)

      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          // Place name skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 120, height: 20)
            .shimmerEffect()

          // "방문 장소" skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 60, height: 14)
            .shimmerEffect()
        }

        Spacer()

        // Travel line skeleton
        RoundedRectangle(cornerRadius: 3)
          .fill(.gray300)
          .frame(width: 123, height: 6)
          .padding(.vertical, 9)
          .shimmerEffect()

        Spacer()
          .frame(width: 24)

        VStack(alignment: .trailing, spacing: 4) {
          // Departure name skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 52, height: 20)
            .shimmerEffect()

          // "출발역" skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 40, height: 14)
            .shimmerEffect()
        }
        .frame(width: 52, alignment: .trailing)
      }

      Spacer()
        .frame(height: 20)

      // Dotted line skeleton
      Path { path in
        path.move(to: CGPoint(x: 0, y: 0.5))
        path.addLine(to: CGPoint(x: 330, y: 0.5))
      }
      .stroke(
        .gray400,
        style: StrokeStyle(
          lineWidth: 1,
          lineCap: .round,
          dash: [1, 4]
        )
      )
      .frame(height: 1)

      Spacer()
        .frame(height: 20)

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          // "총 여정 시간" skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 70, height: 12)
            .shimmerEffect()

          // Duration skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 60, height: 16)
            .shimmerEffect()
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 6) {
          // "열차 출발" skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 50, height: 12)
            .shimmerEffect()

          // Departure time skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 70, height: 16)
            .shimmerEffect()
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(.gray200)
        .overlay {
          RoundedRectangle(cornerRadius: 24)
            .stroke(.neutral200, style: .init(lineWidth: 1))
        }
    )
  }
}

// MARK: - Shimmer Effect Extension
extension View {
  func shimmerEffect() -> some View {
    modifier(ShimmerEffectModifier())
  }
}

private struct ShimmerEffectModifier: ViewModifier {
  @State private var isAnimating = false

  func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { geometry in
          LinearGradient(
            colors: [
              .white.opacity(0),
              .white.opacity(0.28),
              .white.opacity(0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .frame(width: geometry.size.width * 0.55)
          .offset(x: isAnimating ? geometry.size.width * 1.25 : -geometry.size.width * 0.8)
        }
        .clipped()
      }
      .mask(content)
      .onAppear {
        guard !isAnimating else { return }
        withAnimation(
          .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: false)
        ) {
          isAnimating = true
        }
      }
  }
}
