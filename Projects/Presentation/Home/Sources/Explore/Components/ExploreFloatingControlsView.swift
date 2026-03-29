//
//  ExploreFloatingControlsView.swift
//  Home
//

import SwiftUI

import DesignSystem

struct ExploreFloatingControlsView: View {
  private let listButtonWidth: CGFloat = 100
  private let currentLocationButtonWidth: CGFloat = 48
  private let buttonsSpacing: CGFloat = 80

  let showsListButton: Bool
  let controlsBottomPadding: CGFloat
  let onListTap: () -> Void
  let onCurrentLocationTap: () -> Void

  var body: some View {
    Group {
      if showsListButton {
        ZStack {
          listButton
            .frame(maxWidth: .infinity, alignment: .center)

          currentLocationButton
            .offset(x: currentLocationOffset)
        }
        .frame(maxWidth: .infinity)
      } else {
        HStack {
          Spacer()
          currentLocationButton
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, controlsBottomPadding)
  }

  private var currentLocationOffset: CGFloat {
    (listButtonWidth / 2) + buttonsSpacing + (currentLocationButtonWidth / 2)
  }

  private var listButton: some View {
    Button(action: onListTap) {
      HStack(spacing: 6) {
        Image(systemName: "list.bullet")
          .font(.system(size: 14, weight: .semibold))
        Text("목록보기")
          .pretendardCustomFont(textStyle: .body2Medium)
      }
      .foregroundStyle(.gray830)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .frame(width: listButtonWidth, height: 38)
      .background(.staticWhite)
      .clipShape(Capsule())
      .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
    .buttonStyle(.plain)
  }

  private var currentLocationButton: some View {
    Button(action: onCurrentLocationTap) {
      Image(asset: .location)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .frame(width: currentLocationButtonWidth, height: currentLocationButtonWidth)
        .background(.staticWhite, in: Circle())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
    .buttonStyle(.plain)
  }
}
