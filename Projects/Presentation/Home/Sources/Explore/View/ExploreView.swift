//
//  ExploreView.swift
//  Home
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import CoreLocation

import DesignSystem
import Entity

public struct ExploreView: View {
  @Bindable var store: StoreOf<ExploreReducer>
  @Environment(\.dismiss) private var dismiss

  public init(store: StoreOf<ExploreReducer>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      NaverMapComponent(
        locationPermissionStatus: store.locationPermissionStatus,
        currentLocation: store.currentLocation,
        routeInfo: store.routeInfo,
        destination: store.selectedDestination,
        returnToLocation: store.shouldReturnToCurrentLocation
      )
      .ignoresSafeArea(.all)

      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Button {
            dismiss()
          } label: {
            Image(asset: .leftArrow)
              .resizable()
              .scaledToFit()
              .frame(width: 56, height: 56)
              .background(.staticWhite)
              .clipShape(Circle())
          }
          .buttonStyle(.plain)

          HStack {
            Text("강릉역")
              .pretendardCustomFont(textStyle: .titleRegular)
              .foregroundStyle(.staticBlack)

            Spacer()
          }
          .padding(.horizontal, 24)
          .frame(height: 56)
          .background(.staticWhite)
          .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .padding(.top, 8)
        .padding(.horizontal, 20)

        Spacer()

        HStack {
          Spacer()

          Button {
            store.send(.view(.returnToCurrentLocation))
          } label: {
            Image(systemName: "location")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(.staticBlack)
              .frame(width: 56, height: 56)
              .background(.staticWhite)
              .clipShape(Circle())
              .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
          }
          .padding(.trailing, 16)
          .padding(.bottom, 36)
        }
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
    .onDisappear {
      store.send(.view(.onDisappear))
    }
    .alert($store.scope(state: \.alert, action: \.scope.alert))
  }
}
