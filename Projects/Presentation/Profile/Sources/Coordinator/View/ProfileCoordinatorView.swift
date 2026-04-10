//
//  ProfileCoordinatorView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import  SwiftUI

import ComposableArchitecture
import DesignSystem
import TCAFlow
import Web

public struct ProfileCoordinatorView: View {
  @Bindable var store: StoreOf<ProfileCoordinator>

  public init(store: StoreOf<ProfileCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .profile(let profileStore):
          ProfileView(store: profileStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()


        case .setting(let settingStore):
          SettingView(store: settingStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()

        case .withDraw(let withDrawStore):
          WithDrawView(store: withDrawStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()

        case .notification(let notificationStore):
          NotificationSettingView(store: notificationStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()

        case .web(let webStore):
          WebView(store: webStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()
      }
    }
  }
}
