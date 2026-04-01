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
      backgroundView
      mainContentView
      mapDropdownOverlay
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}

extension SettingView {
  @ViewBuilder
  private var backgroundView: some View {
    Color.staticWhite
      .ignoresSafeArea()
  }

  @ViewBuilder
  private var mainContentView: some View {
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

  @ViewBuilder
  private var mapDropdownOverlay: some View {
    if store.showMapDropdown {
      ZStack {
        Color.clear
          .ignoresSafeArea()
          .onTapGesture {
            store.send(.view(.toggleMapDropdown))
          }

        VStack(spacing: 0) {
          Spacer()
            .frame(height: 8 + 44 + 18 + 56 + 56 + 56)

          HStack {
            Spacer()
            dropdownContent
              .padding(.trailing, 32)
          }

          Spacer()
        }
      }
      .transition(.opacity)
    }
  }

  @ViewBuilder
  private var dropdownContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(ExternalMapType.allCases.enumerated()), id: \.element) { index, mapType in
        dropdownButton(for: mapType, at: index)

        if index < ExternalMapType.allCases.count - 1 {
          Rectangle()
            .fill(.enableColor)
            .frame(height: 1)
        }
      }
    }
    .frame(width: 236)
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 30))
    .overlay(
      RoundedRectangle(cornerRadius: 30)
        .stroke(.enableColor, lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
  }

  @ViewBuilder
  private func dropdownButton(for mapType: ExternalMapType, at index: Int) -> some View {
    Button {
      store.send(.view(.mapTypeSelected(mapType)))
    } label: {
      HStack(spacing: 12) {
        Text(mapType.description)
          .pretendardCustomFont(textStyle: .bodyMedium)
          .foregroundStyle(.gray800)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()

        if store.userSession.mapType == mapType {
          Image(asset: .rowCheck)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
        }
      }
      .frame(height: 44)
      .padding(.horizontal, 20)
      .padding(.top, index == 0 ? 4 : 0)
      .padding(.bottom, index == 2 ? 4 : 0)
      .background(.white)
    }
    .buttonStyle(ScaleButtonStyle())
  }

  @ViewBuilder
  private var notificationSettingsSection: some View {
    settingsSection {
      SettingMenuRowView(
        title: "시간 알림",
        action: {
          store.send(.delegate(.presentNotificationSetting))
        }
      )

      SettingMenuRowView(
        title: "위치 접근 권한",
        trailingText: "설정",
        action: {
          openAppSettings()
        }
      )

      SettingMenuRowView(
        title: "연동된 지도",
        trailingText: store.userSession.mapType.description,
        accessory: .dropdown,
        showsDivider: false,
        action: {
          store.send(.view(.toggleMapDropdown))
        }
      )
    }
  }

  @ViewBuilder
  private var accountSettingsSection: some View {
    settingsSection {
      SettingMenuRowView(
        title: "서비스 이용 약관",
        action: {
          store.send(.delegate(.presentServicePolicy))
        }
      )

      SettingMenuRowView(
        title: "개인정보 처리방침",
        action: {
          store.send(.delegate(.presentPrivacyPolicy))
        }
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

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .opacity(configuration.isPressed ? 0.8 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}
