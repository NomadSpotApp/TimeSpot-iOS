//
//  ProfileSkeletonView.swift
//  Profile
//
//  Created by Wonji Suh on 3/25/26.
//

import SwiftUI
import DesignSystem

public struct ProfileSkeletonView: View {

  public init() {}

  public var body: some View {
    ZStack {
      Color.gray100
        .edgesIgnoringSafeArea(.all)

      VStack {
        Spacer()
          .frame(height: 8)

        // Navigation Bar Skeleton
        CustomNavigationBar(
          title: "마이페이지",
          leftImage: .leftArrow,
          rightImage: .setting,
          leftAction: {},
          rightAction: {}
        )

        profileInfoCardSkeletonView()

        travelHistorySkeleton()

        Spacer()
      }
      .padding(.horizontal, 16)
    }
  }
}

extension ProfileSkeletonView {
  @ViewBuilder
  private func profileInfoCardSkeletonView() -> some View {
    VStack(alignment: .leading) {
      VStack {
        Spacer()
          .frame(height: 12)

        HStack {
          // Name skeleton
          RoundedRectangle(cornerRadius: 6)
            .fill(.blueGray600)
            .frame(width: 100, height: 24)
            .shimmerEffect()

          Spacer()
        }
        .padding(.horizontal, 8)

        Spacer()
          .frame(height: 3)

        HStack {
          // Icon skeleton
          Circle()
            .fill(.blueGray600)
            .frame(width: 16, height: 16)
            .shimmerEffect()

          Spacer()
            .frame(width: 4)

          // Email skeleton
          RoundedRectangle(cornerRadius: 4)
            .fill(.blueGray600)
            .frame(width: 150, height: 14)
            .shimmerEffect()

          Spacer()
        }
        .padding(.horizontal, 8)

        Spacer()
          .frame(height: 24)

        HStack {
          Spacer()

          VStack(alignment: .center) {
            // "방문한 장소" skeleton
            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray600)
              .frame(width: 60, height: 12)
              .shimmerEffect()

            Spacer()
              .frame(height: 4)

            // Count skeleton
            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray600)
              .frame(width: 40, height: 16)
              .shimmerEffect()
          }

          Spacer()

          Image(asset: .lineHeight)
            .resizable()
            .scaledToFit()
            .frame(height: 48)

          Spacer()

          VStack(alignment: .center) {
            // "탐험 시간" skeleton
            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray600)
              .frame(width: 50, height: 12)
              .shimmerEffect()

            Spacer()
              .frame(height: 4)

            // Time skeleton
            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray600)
              .frame(width: 70, height: 16)
              .shimmerEffect()
          }

          Spacer()
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 11)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.blueGray800)
        )
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.navy900)
      )
    }
  }

  @ViewBuilder
  private func travelHistorySkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
        .frame(height: 40)

      HStack {
        // "나의 히스토리" skeleton
        RoundedRectangle(cornerRadius: 6)
          .fill(.gray300)
          .frame(width: 120, height: 20)
          .shimmerEffect()

        Spacer()

        // Sort button skeleton
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray300)
          .frame(width: 80, height: 16)
          .shimmerEffect()
      }

      Spacer()
        .frame(height: 20)

      ScrollView(.vertical) {
        VStack(spacing: 12) {
          ForEach(0..<3, id: \.self) { _ in
            TravelHistoryCardSkeletonView()
          }
        }
        .padding(.bottom, 24)
      }
      .scrollIndicators(.hidden)
    }
  }
}
