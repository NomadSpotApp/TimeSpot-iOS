//
//  SettingView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import SwiftUI
import UIKit

import DesignSystem
import Entity

import ComposableArchitecture

public struct SettingView: View {
  @Bindable var store: StoreOf<SettingFeature>
  @Environment(\.openURL) private var openURL

  public init(
    store: StoreOf<SettingFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack(alignment: .top) {
      Color.staticWhite
        .ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()
          .frame(height: 8)

        CustomNavigationBackBar(
          buttonAction: {
            store.send(.delegate(.presentBack))
          },
          title: "설정"
        )

        Spacer()
          .frame(height: 18)

        notificationSettingsSection

        Spacer()
          .frame(height: 24)

        accountSettingsSection

        Spacer()
      }
      .padding(.horizontal, 16)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}

extension SettingView {
  @ViewBuilder
  private var notificationSettingsSection: some View {
    settingsSection {
      SettingMenuRowView(
        title: "시간 알림",
        action: {

        }
      )

      SettingMenuRowView(
        title: "위치 접근 권한",
        trailingText: "설정",
        action: {
          openAppSettings()
        }
      )

      Menu {
        ForEach(ExternalMapType.allCases) { mapType in
          Button {
            store.send(.view(.mapTypeSelected(mapType)))
          } label: {
            if store.userSession.mapType == mapType {
              Label(mapType.description, systemImage: "checkmark")
                .pretendardCustomFont(textStyle: .bodyMedium)
                .foregroundStyle(.gray800)
            } else {
              Text(mapType.description)
                .pretendardCustomFont(textStyle: .bodyMedium)
                .foregroundStyle(.gray800)
            }
          }
        }
      } label: {
        SettingMenuRowView(
          title: "연동된 지도",
          trailingText: store.userSession.mapType.description,
          accessory: .dropdown,
          showsDivider: false
        )
      }
    }
  }

  @ViewBuilder
  private var accountSettingsSection: some View {
    settingsSection {
      SettingMenuRowView(
        title: "서비스 이용 약관"
      )

      SettingMenuRowView(
        title: "개인정보 처리방침"
      )

      SettingMenuRowView(
        title: "로그아웃",
        action: {
          store.send(.view(.logoutRowTapped))
        }
      )

      SettingMenuRowView(
        title: "회원 탈퇴",
        showsDivider: false,
        action:  {
          store.send(.delegate(.presentWithDraw))
        }
      )
    }
  }

  @ViewBuilder
  private func settingsSection<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(spacing: 0) {
      content()
    }
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(.gray200)
    )
  }

  private func openAppSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
      return
    }
    openURL(settingsURL)
  }
}
