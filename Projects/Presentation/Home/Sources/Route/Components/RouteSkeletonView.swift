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
    ZStack {
      VStack {
        // 🏷️ 상단 헤더 스켈레톤 (역 이름)
        headerSkeleton()
          .padding(.horizontal, 16)
          .padding(.top, 8)

        Spacer()

        // 🗺️ 하단 길찾기 시작 버튼
        routeStartButtonSkeleton()
          .padding(.horizontal, 16)
          .padding(.bottom, 32)
      }

      // 📊 중앙 상단에 떠있는 경로 정보 카드
      VStack {
        routeInfoCardSkeleton()
          .padding(.horizontal, 16)
          .padding(.top, 80) // 헤더 아래 위치

        Spacer()
      }
    }
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
    VStack(alignment: .leading, spacing: 12) {
      // 도보 라벨
      HStack {
        RoundedRectangle(cornerRadius: 6)
          .fill(.gray200)
          .frame(width: 30, height: 16)
          .skeletonShimmer()

        Spacer()
      }

      // 큰 시간과 거리 정보
      HStack(alignment: .center) {
        // 왼쪽: 큰 시간 텍스트 (3시간 30분)
        VStack(alignment: .leading, spacing: 4) {
          RoundedRectangle(cornerRadius: 8)
            .fill(.gray200)
            .frame(width: 120, height: 36)
            .skeletonShimmer()
        }

        Spacer()

        // 오른쪽: 거리 텍스트 (16.4km)
        VStack(alignment: .trailing) {
          RoundedRectangle(cornerRadius: 6)
            .fill(.gray200)
            .frame(width: 60, height: 24)
            .skeletonShimmer()
        }
      }

      // 예상 도착 시간
      HStack {
        Circle()
          .fill(.gray200)
          .frame(width: 16, height: 16)
          .skeletonShimmer()

        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 120, height: 16)
          .skeletonShimmer()

        Spacer()
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
  }

  @ViewBuilder
  private func routeStartButtonSkeleton() -> some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(.gray300)
      .frame(height: 48)
      .skeletonShimmer()
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