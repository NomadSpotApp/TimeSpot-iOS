//
//  RouteNotificationView.swift
//  Home
//
//  Created by Wonji Suh  on 3/31/26.
//

import SwiftUI

import DesignSystem
import ComposableArchitecture


public struct RouteNotificationView: View {
  @Bindable var store: StoreOf<RouteNotificationFeature>

  public init(store: StoreOf<RouteNotificationFeature>) {
    self.store = store
  }

  public var body: some View {

  }
}
