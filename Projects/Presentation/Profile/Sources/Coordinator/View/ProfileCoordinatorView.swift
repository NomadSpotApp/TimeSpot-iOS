//
//  ProfileCoordinatorView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import  SwiftUI

import ComposableArchitecture
import TCACoordinators

public struct ProfileCoordinatorView: View {
  @Bindable var store: StoreOf<ProfileCoordinator>

  public init(store: StoreOf<ProfileCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { (screen: StoreOf<ProfileCoordinator.ProfileScreen>) in
      switch screen.case {
        case .profile(let profileStore):
          ProfileView(store: profileStore)
            .navigationBarBackButtonHidden()


        case .setting(let settingStore):
          SettingView(store: settingStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing),
              removal: .move(edge: .leading)
            ))

        case .withDraw(let withDrawStore):
          WithDrawView(store: withDrawStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing),
              removal: .move(edge: .leading)
            ))

        case .notification(let notificationStore):
          NotificationSettingView(store: notificationStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing),
              removal: .move(edge: .leading)
            ))
      }
    }
  }
}
