//
//  ExploreSkeletonView.swift
//  Home
//

import SwiftUI

import DesignSystem

struct ExploreSkeletonView: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [.gray200, .gray100],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        headerSection()
          .padding(.top, 8)
          .padding(.horizontal, 20)

        Spacer()

        bottomSection()
      }
    }
  }
}

private extension ExploreSkeletonView {
  @ViewBuilder
  func headerSection() -> some View {
    VStack(spacing: 0) {
      HStack(spacing: 10) {
        Circle()
          .fill(.staticWhite.opacity(0.9))
          .frame(width: 48, height: 48)

        RoundedRectangle(cornerRadius: 18)
          .fill(.staticWhite.opacity(0.9))
          .frame(height: 48)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(0..<5, id: \.self) { index in
            Capsule()
              .fill(.staticWhite.opacity(0.9))
              .frame(width: CGFloat([72, 64, 80, 68, 76][index]), height: 36)
          }
        }
        .padding(.top, 10)
        .padding(.horizontal, 2)
      }
    }
  }

  @ViewBuilder
  func bottomSection() -> some View {
    VStack(spacing: 16) {
      HStack {
        Spacer()

        Circle()
          .fill(.staticWhite)
          .frame(width: 48, height: 48)
          .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
      }
      .padding(.horizontal, 16)

      selectedSpotCardSkeleton()
        .padding(.horizontal, 16)
    }
    .padding(.bottom, 36)
  }

  @ViewBuilder
  func selectedSpotCardSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 0) {
          Capsule()
            .fill(.gray200)
            .frame(width: 88, height: 24)
            .padding(.bottom, 12)

          RoundedRectangle(cornerRadius: 6)
            .fill(.gray200)
            .frame(height: 22)
            .padding(.bottom, 6)

          RoundedRectangle(cornerRadius: 6)
            .fill(.gray200)
            .frame(width: 120, height: 16)
            .padding(.bottom, 12)

          RoundedRectangle(cornerRadius: 4)
            .fill(.gray200)
            .frame(width: 180, height: 14)
            .padding(.bottom, 8)

          HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
              .fill(.gray200)
              .frame(width: 52, height: 14)

            RoundedRectangle(cornerRadius: 4)
              .fill(.gray200)
              .frame(width: 120, height: 14)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        RoundedRectangle(cornerRadius: 16)
          .fill(.gray200)
          .frame(width: 92, height: 112)
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 20)

      RoundedRectangle(cornerRadius: 25)
        .fill(.gray850)
        .frame(height: 55)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
  }
}
