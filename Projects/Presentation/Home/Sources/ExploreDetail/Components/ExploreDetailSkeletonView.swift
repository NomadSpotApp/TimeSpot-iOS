//
//  ExploreDetailSkeletonView.swift
//  Home
//
//  Created by Wonji Suh  on 3/29/26.
//

import SwiftUI
import DesignSystem

public struct ExploreDetailSkeletonView: View {
  public init() {}

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      RoundedRectangle(cornerRadius: 4)
        .fill(.gray200)
        .frame(width: 84, height: 14)
        .skeletonShimmer()
        .padding(.top, 12)

      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 20)
          .fill(.gray200)
          .frame(height: 180)
          .frame(maxWidth: .infinity)
          .skeletonShimmer()

        RoundedRectangle(cornerRadius: 20)
          .fill(.gray200)
          .frame(width: 84, height: 180)
          .skeletonShimmer()
      }
      .padding(.top, 24)

      HStack(spacing: 0) {
        skeletonMetricColumn()
        divider
        skeletonMetricColumn()
        divider
        skeletonMetricColumn()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 16)
      .background(.staticWhite)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .stroke(.gray300, lineWidth: 1)
      }
      .padding(.top, 24)

      RoundedRectangle(cornerRadius: 20)
        .fill(.gray200)
        .frame(height: 84)
        .skeletonShimmer()
        .padding(.top, 24)

      VStack(alignment: .leading, spacing: 16) {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 64, height: 14)
          .skeletonShimmer()

        skeletonInfoRow(lineWidth: 180)
        skeletonInfoRow(lineWidth: 120)
        skeletonInfoRow(lineWidth: 200)
      }
      .padding(.top, 24)

      RoundedRectangle(cornerRadius: 20)
        .fill(.gray200)
        .frame(height: 180)
        .skeletonShimmer()
        .padding(.top, 24)

      Capsule()
        .fill(.gray200)
        .frame(height: 56)
        .skeletonShimmer()
        .padding(.top, 24)
    }
  }

  @ViewBuilder
  private func skeletonMetricColumn() -> some View {
    VStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 4)
        .fill(.gray200)
        .frame(width: 46, height: 16)
        .skeletonShimmer()

      RoundedRectangle(cornerRadius: 4)
        .fill(.gray200)
        .frame(width: 34, height: 12)
        .skeletonShimmer()
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func skeletonInfoRow(lineWidth: CGFloat) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Circle()
        .fill(.gray200)
        .frame(width: 20, height: 20)
        .skeletonShimmer()

      VStack(alignment: .leading, spacing: 6) {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 56, height: 12)
          .skeletonShimmer()

        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: lineWidth, height: 14)
          .skeletonShimmer()
      }

      Spacer(minLength: 0)
    }
  }

  private var divider: some View {
    Rectangle()
      .fill(.gray300)
      .frame(width: 1, height: 34)
  }
}

private extension View {
  func skeletonShimmer() -> some View {
    modifier(ExploreDetailSkeletonShimmerModifier())
  }
}

private struct ExploreDetailSkeletonShimmerModifier: ViewModifier {
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
