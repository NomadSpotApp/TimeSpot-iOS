//
//  ExploreListSkeletonView.swift
//  Home
//

import SwiftUI

import DesignSystem

struct ExploreListSkeletonView: View {
  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        VStack(spacing: 20) {
          HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
              .fill(.gray200)
              .frame(width: 40, height: 40)

            RoundedRectangle(cornerRadius: 20)
              .fill(.gray200)
              .frame(height: 44)
          }

          VStack(spacing: 12) {
            HStack(spacing: 8) {
              ForEach(0..<4, id: \.self) { index in
                Capsule()
                  .fill(.gray200)
                  .frame(width: CGFloat([80, 60, 70, 90][index]), height: 36)
              }
              Spacer()
            }

            HStack {
              Capsule()
                .fill(.gray200)
                .frame(width: 100, height: 36)
              Spacer()
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)

        HStack {
          Spacer()
          RoundedRectangle(cornerRadius: 6)
            .fill(.gray200)
            .frame(width: 100, height: 24)
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)

        ScrollView(showsIndicators: false) {
          LazyVStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
              ExploreListSkeletonItemView()
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 100)
        }
        .background(.gray100)
      }

      VStack {
        Spacer()
        Capsule()
          .fill(.gray200)
          .frame(width: 108, height: 44)
          .padding(.bottom, 40)
      }
    }
  }
}

private struct ExploreListSkeletonItemView: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(.staticWhite)
      .frame(height: 140)
      .overlay {
        HStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
              .fill(.gray200)
              .frame(width: 60, height: 20)

            RoundedRectangle(cornerRadius: 6)
              .fill(.gray200)
              .frame(height: 18)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 140, height: 14)

              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 100, height: 14)
            }

            Spacer()

            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 50, height: 12)

              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 80, height: 12)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          RoundedRectangle(cornerRadius: 12)
            .fill(.gray200)
            .frame(width: 100, height: 100)
        }
        .padding(16)
      }
  }
}
