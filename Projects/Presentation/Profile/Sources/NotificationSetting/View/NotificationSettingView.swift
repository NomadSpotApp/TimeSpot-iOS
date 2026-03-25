//
//  NotificationSettingView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/26/26.
//

import SwiftUI

import DesignSystem
import Entity

import ComposableArchitecture


public struct NotificationSettingView: View {
  @Bindable var store: StoreOf<NotificationSettingFeature>

  public init(
    store: StoreOf<NotificationSettingFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.staticWhite
        .edgesIgnoringSafeArea(.all)

      VStack {
        Spacer()
          .frame(height: 8)

        CustomNavigationBackBar(
          buttonAction: {
            store.send(.delegate(.presentBack))
          },
          title: "시간 설정"
        )

        notificationOptionMenuView()

        Spacer()
      }
      .padding(.horizontal, 16)
    }
  }
}


extension NotificationSettingView {
  @ViewBuilder
  fileprivate func notificationOptionMenuView() -> some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: 48)

      VStack(spacing: 0) {
        ForEach(NotificationOption.allCases) { option in
          Button {
            store.send(.view(.notificationOptionTapped(option)))
          } label: {
            HStack(spacing: 12) {
              Text(option.title)
                .pretendardCustomFont(textStyle: .bodyMedium)
                .foregroundStyle(.gray900)

              Spacer()

              if store.selectedOptions.contains(option) {
                Image(systemName: "checkmark")
                  .font(.system(size: 18, weight: .medium))
                  .foregroundStyle(.gray550)
              }
            }
            .frame(height: 58)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          if option != .fifteenMinutesBefore {
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
}
