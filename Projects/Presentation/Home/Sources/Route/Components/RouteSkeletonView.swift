//
//  RouteSkeletonView.swift
//  Home
//
//  Created by Wonji Suh  on 3/30/26.
//

import SwiftUI
import DesignSystem

/// 경로 계산 중 로딩 상태를 보여주는 스켈레톤 뷰
public struct RouteSkeletonView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 16) {
      // 🏷️ 상단 헤더 스켈레톤 (역 이름)
      headerSkeleton()

      Spacer()

      // 📊 경로 정보 카드 스켈레톤
      routeInfoCardSkeleton()
        .padding(.bottom, 32)
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  @ViewBuilder
  private func headerSkeleton() -> some View {
    VStack(spacing: 12) {
      HStack {
        // 뒤로 가기 버튼
        Circle()
          .fill(.gray200)
          .frame(width: 40, height: 40)
          .skeletonShimmer()

        // 역 이름
        RoundedRectangle(cornerRadius: 20)
          .fill(.gray200)
          .frame(height: 40)
          .frame(maxWidth: .infinity)
          .skeletonShimmer()

        // 오른쪽 공간 (대칭을 위해)
        Circle()
          .fill(.clear)
          .frame(width: 40, height: 40)
      }
    }
  }

  @ViewBuilder
  private func routeInfoCardSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      // 도보 라벨
      HStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(.gray200)
          .frame(width: 40, height: 20)
          .skeletonShimmer()

        Spacer()

        // 로딩 스피너 영역
        Circle()
          .fill(.gray200)
          .frame(width: 20, height: 20)
          .skeletonShimmer()
      }

      Spacer()
        .frame(height: 4)

      // 시간과 거리 정보
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          // 큰 시간 텍스트
          RoundedRectangle(cornerRadius: 6)
            .fill(.gray200)
            .frame(width: 80, height: 32)
            .skeletonShimmer()
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          // 거리 텍스트
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray200)
            .frame(width: 60, height: 20)
            .skeletonShimmer()
        }
      }

      Spacer()
        .frame(height: 8)

      // 예상 도착 시간
      HStack {
        Circle()
          .fill(.gray200)
          .frame(width: 14, height: 14)
          .skeletonShimmer()

        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 100, height: 14)
          .skeletonShimmer()

        Spacer()
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .background(
      RoundedRectangle(cornerRadius: 28)
        .stroke(.gray300, style: .init(lineWidth: 1))
        .background(.gray100)
    )
    .cornerRadius(28)
  }
}

private extension View {
  func skeletonShimmer() -> some View {
    modifier(RouteSkeletonShimmerModifier())
  }
}

private struct RouteSkeletonShimmerModifier: ViewModifier {
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
          .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: false)
        ) {
          isAnimating = true
        }
      }
  }
}

#Preview {
  ZStack {
    Color.gray.opacity(0.1)
      .edgesIgnoringSafeArea(.all)

    RouteSkeletonView()
  }
}