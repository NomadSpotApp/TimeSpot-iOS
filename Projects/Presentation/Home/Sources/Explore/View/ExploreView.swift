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
      mapView()

      VStack(spacing: 0) {
        headerSection()
          .padding(.top, 8)
          .padding(.horizontal, 20)

        Spacer()

        currentLocationButton()
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

private extension ExploreView {
  @ViewBuilder
  func mapView() -> some View {
    NaverMapComponent(
      locationPermissionStatus: store.locationPermissionStatus,
      currentLocation: store.currentLocation,
      routeInfo: store.routeInfo,
      destination: store.selectedDestination,
      returnToLocation: store.shouldReturnToCurrentLocation
    )
    .ignoresSafeArea(.all)
  }

  @ViewBuilder
  func headerSection() -> some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        backButton()
        searchBar()
      }

      categoryScrollView()
        .padding(.top, 12)
    }
  }

  @ViewBuilder
  func backButton() -> some View {
    Button {
      dismiss()
    } label: {
      Image(asset: .leftArrow)
        .resizable()
        .scaledToFit()
        .frame(width: 56, height: 56)
        .background(.staticWhite)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.08), radius: 12, y: 2)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func searchBar() -> some View {
    HStack {
      Text("\(store.userSession.travelStationName)역")
        .pretendardFont(family: .Regular, size: 18)
        .foregroundStyle(.staticBlack)

      Spacer()
    }
    .padding(.horizontal, 24)
    .frame(height: 56)
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 28))
    .shadow(color: .black.opacity(0.08), radius: 12, y: 2)
  }

  @ViewBuilder
  func categoryScrollView() -> some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(ExploreCategory.allCases, id: \.self) { category in
            categoryChip(category) {
              scrollToCategory(category, with: proxy)
            }
            .id(category)
          }
        }
        .padding(.horizontal, 2)
      }
      .onAppear {
        scrollToCategory(store.selectedCategory, with: proxy, animated: false)
      }
      .onChange(of: store.selectedCategory) { _, category in
        scrollToCategory(category, with: proxy)
      }
    }
  }

  @ViewBuilder
  func categoryChip(
    _ category: ExploreCategory,
    onTap: @escaping () -> Void
  ) -> some View {
    let isSelected = store.selectedCategory == category

    Button {
      store.send(.view(.categoryTapped(category)))
      onTap()
    } label: {
      HStack(spacing: 4) {
        categoryIcon(for: category, isSelected: isSelected)

        Text(category.title)
          .pretendardFont(family: .Medium, size: 14)
          .foregroundStyle(isSelected ? .staticBlack : .gray700)
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 16)
      .background(isSelected ? .orange200 : .staticWhite)
      .overlay {
        Capsule()
          .stroke(isSelected ? .orange800 : .gray300, lineWidth: 1)
      }
      .clipShape(Capsule())
      .shadow(color: .black.opacity(isSelected ? 0.04 : 0.08), radius: 8, y: 2)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func currentLocationButton() -> some View {
    HStack {
      Spacer()

      Button {
        store.send(.view(.returnToCurrentLocation))
      } label: {
        Image(asset: .location)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)
          .frame(width: 48, height: 48)
          .background(.staticWhite, in: Circle())
          .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
      }
      .padding(.trailing, 16)
      .padding(.bottom, 36)
    }
  }

  func scrollToCategory(
    _ category: ExploreCategory,
    with proxy: ScrollViewProxy,
    animated: Bool = true
  ) {
    let action = {
      proxy.scrollTo(category == .all ? ExploreCategory.all : category, anchor: .leading)
    }

    if animated {
      withAnimation(.easeInOut(duration: 0.2)) {
        action()
      }
    } else {
      action()
    }
  }

  @ViewBuilder
  func categoryIcon(
    for category: ExploreCategory,
    isSelected: Bool
  ) -> some View {
    switch category {
    case .all:
      Image(asset: isSelected ? .tapAll : .all)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
    case .cafe:
      if isSelected {
        Image(asset: .tapCaffee)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
      } else {
        Image(systemName: "cup.and.saucer.fill")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.gray600)
          .frame(width: 16, height: 16)
      }
    case .restaurant:
      Image(asset: isSelected ? .tapFood : .food)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
    case .activity:
      Image(asset: isSelected ? .tapGame : .game)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
        .foregroundStyle(isSelected ? .orange800 : .gray700)

      case .etc:
        Image(asset: isSelected ? .tapEtc : .etc)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
          .foregroundStyle(isSelected ? .orange800 : .gray700)

    }
  }
}
