//
//  ExploreListSkeletonView.swift
//  Home
//

import SwiftUI
import DesignSystem

public struct ExploreListSkeletonView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      // 헤더 영역
      headerSection()
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .background(.staticWhite)

      // 정렬 섹션
      sortSection()
        .padding(.top, 28)
        .padding(.horizontal, 16)
        .background(.staticWhite)

      // 리스트 영역
      ScrollView(showsIndicators: false) {
        LazyVStack(spacing: 12) {
          ForEach(0..<8) { _ in
            skeletonListItem()
          }

          Spacer(minLength: 80)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
      }
      .background(.gray100)
    }
    .background(.staticWhite)
  }

  @ViewBuilder
  private func headerSection() -> some View {
    HStack(spacing: 16) {
      // 뒤로 가기 버튼
      Circle()
        .fill(.gray200)
        .frame(width: 40, height: 40)
        .skeletonShimmer()

      // 검색창
      HStack(spacing: 8) {
        // 검색 아이콘 영역
        Circle()
          .fill(.gray200)
          .frame(width: 20, height: 20)
          .skeletonShimmer()

        // 검색 텍스트 영역
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(height: 16)
          .skeletonShimmer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.gray100)
      .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // 카테고리 필터 버튼들
    HStack(spacing: 12) {
      ForEach(0..<4) { index in
        Capsule()
          .fill(.gray200)
          .frame(width: index == 0 ? 60 : [80, 70, 90][index-1], height: 32)
          .skeletonShimmer()
      }

      Spacer()
    }
    .padding(.top, 16)
  }

  @ViewBuilder
  private func sortSection() -> some View {
    HStack {
      Spacer()

      // 정렬 드롭다운
      HStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 80, height: 14)
          .skeletonShimmer()

        Circle()
          .fill(.gray200)
          .frame(width: 12, height: 12)
          .skeletonShimmer()
      }
    }
  }

  @ViewBuilder
  private func skeletonListItem() -> some View {
    HStack(alignment: .top, spacing: 16) {
      // 왼쪽 텍스트 영역
      VStack(alignment: .leading, spacing: 8) {
        // 제목
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 120, height: 16)
          .skeletonShimmer()

        // 부제목/카테고리
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 80, height: 12)
          .skeletonShimmer()

        // 상태 배지
        Capsule()
          .fill(.gray200)
          .frame(width: 60, height: 20)
          .skeletonShimmer()

        // 거리/시간 정보
        VStack(alignment: .leading, spacing: 4) {
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray200)
            .frame(width: 100, height: 12)
            .skeletonShimmer()

          RoundedRectangle(cornerRadius: 4)
            .fill(.gray200)
            .frame(width: 140, height: 12)
            .skeletonShimmer()
        }
      }

      Spacer()

      // 오른쪽 이미지 영역
      RoundedRectangle(cornerRadius: 12)
        .fill(.gray200)
        .frame(width: 80, height: 80)
        .skeletonShimmer()
    }
    .padding(16)
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

private extension View {
  func skeletonShimmer() -> some View {
    modifier(ExploreListSkeletonShimmerModifier())
  }
}

private struct ExploreListSkeletonShimmerModifier: ViewModifier {
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
