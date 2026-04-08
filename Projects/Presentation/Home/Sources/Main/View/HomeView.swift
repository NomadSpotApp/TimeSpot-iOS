//
//  HomeView.swift
//  Home
//
//  Created by Wonji Suh  on 3/24/26.
//

import SwiftUI

import DesignSystem
import Utill

import ComposableArchitecture

public struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  // MARK: - Layout Constants
  private enum Layout {
    enum Hero {
      static let height: CGFloat = 524
      static let cornerRadius: CGFloat = 40
    }

    enum TimePicker {
      static let width: CGFloat = 176
      static let height: CGFloat = 180
      static let offset = UIOffset(horizontal: -184, vertical: 492)
      static let cornerRadius: CGFloat = 28
    }

    enum TimeCapsule {
      static let height: CGFloat = 77
      static let cornerRadius: CGFloat = 24
    }

    enum TimeDisplay {
      static let cornerRadius: CGFloat = 28
    }
  }


  public init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.gray300.opacity(0.5)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 0) {
        logoContentView()
          .zIndex(1)

        timeLeftView()
          .padding(.top, 14)
          .zIndex(0)

        exploreNearbyButton()
          .padding(.top, 28)

        Spacer()
      }
    }
    .presentDSModal(
      item: $store.scope(state: \.trainStation, action: \.trainStation),
      height: .fraction(0.88),
      showDragIndicator: true
    ) { trainStationStore in
      TrainStationView(store: trainStationStore)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
    .toastOverlay(
      position: .bottom,
      horizontalPadding: 20,
      bottomPadding: 100
    )
    .onAppear {
      store.send(.view(.onAppear))
    }
    .onChange(of: store.shouldShowDepartureWarningToast) { _, shouldShow in
      guard shouldShow else { return }
      ToastManager.shared.showWarning(HomeFeature.Strings.insufficientWaitTime)
    }
  }
}



extension HomeView {

  @ViewBuilder
  fileprivate func logoContentView() -> some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        ZStack(alignment: .top) {
          Image(asset: .homeLogo)
            .resizable()
            .scaledToFill()
            .frame(width: geometry.size.width, height: Layout.Hero.height, alignment: .top)
            .scaleEffect(1.06, anchor: .top)
            .ignoresSafeArea(edges: .top)

          VStack {
            navigationBar()

            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

          VStack(spacing: 8) {
            selectStationView()

            selectTrainTimeView()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .padding(.bottom, 28)
        }
        .frame(width: geometry.size.width, height: Layout.Hero.height)
        .background(.clear)
        .clipShape(
          UnevenRoundedRectangle(
            cornerRadii: .init(
              bottomLeading: Layout.Hero.cornerRadius,
              bottomTrailing: Layout.Hero.cornerRadius
            )
          )
        )

        if store.departureTimePickerVisible {
          departureTimePickerView()
            .offset(x: geometry.size.width + Layout.TimePicker.offset.horizontal, y: Layout.TimePicker.offset.vertical)
            .zIndex(2)
        }
      }
    }
    .frame(height: Layout.Hero.height)
  }

  @ViewBuilder
  fileprivate func navigationBar() -> some View {
    HStack {
      Spacer()

      Button {
        store.send(.view(.profileButtonTapped))
      } label: {
        Image(asset: .profile)
          .resizable()
          .scaledToFit()
          .frame(width: 48, height: 48)
      }
      .buttonStyle(.plain)
    }
    .padding(.top, 10)
    .padding(.horizontal, 14)
  }



  @ViewBuilder
  fileprivate func selectStationView() -> some View {
    Button {
      store.send(.view(.selectStationButtonTapped))
    } label: {
      VStack(alignment: .center, spacing: 0) {
        Text(store.todayDate.formattedKoreanDateWithWeekday())
          .pretendardCustomFont(textStyle: .body2Medium)
          .foregroundStyle(.gray900.opacity(0.9))
          .padding(.bottom, 4)

        Text(store.hasSelectedStation ? store.selectedStation.displayName : store.selectedStation.homeTitle)
          .pretendardFont(family: .Bold, size: 64)
          .foregroundStyle(store.isSelected || store.hasSelectedStation ? .gray900 : .slateGray)
          .tracking(-2.2)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  fileprivate func selectTrainTimeView() -> some View {
    HStack(alignment: .top, spacing: 10) {
      timeCapsuleView(
        title: HomeFeature.Strings.currentTime,
        time: store.currentTime.formattedKoreanTime(),
        timeColor: .gray900,
        backgroundColor: .gray100
      )

      Button {
        store.send(.view(.departureTimeButtonTapped))
      } label: {
        timeCapsuleView(
          title: HomeFeature.Strings.departureTime,
          time: store.isDepartureTimeSet
            ? store.departureTime.formattedKoreanTime()
            : store.currentTime.formattedKoreanTime(),
          timeColor: store.isDepartureTimeSet ? .gray900 : .enableColor,
          backgroundColor: .gray100
        )
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
  }

  @ViewBuilder
  fileprivate func departureTimePickerView() -> some View {
    DatePicker(
      HomeFeature.Strings.departureTimeSelection,
      selection: $store.departureTime,
      displayedComponents: [.hourAndMinute]
    )
    .datePickerStyle(.wheel)
    .labelsHidden()
    .environment(\.locale, Locale(identifier: "ko_KR"))
    .onChange(of: store.departureTime) { _, newValue in
      store.send(.view(.departureTimeChanged(newValue)))
    }
    .frame(height: Layout.TimePicker.height)
    .clipped()
    .frame(width: Layout.TimePicker.width)
    .background(.gray300)
    .clipShape(RoundedRectangle(cornerRadius: Layout.TimePicker.cornerRadius))
  }

  @ViewBuilder
  fileprivate func timeCapsuleView(
    title: String,
    time: String,
    timeColor: Color,
    backgroundColor: Color
  ) -> some View {
    VStack(spacing: 4) {
      Text(title)
        .pretendardCustomFont(textStyle: .caption)
        .foregroundStyle(.gray700)

      Text(time)
        .pretendardCustomFont(textStyle: .bodyMedium)
        .foregroundStyle(timeColor)
    }
    .frame(maxWidth: .infinity)
    .frame(height: Layout.TimeCapsule.height)
    .background(backgroundColor)
    .cornerRadius(Layout.TimeCapsule.cornerRadius)
  }


  @ViewBuilder
  fileprivate func timeLeftView() -> some View {
    HStack {
      Spacer()

      VStack {
        Text(store.remainingHoursText)
          .pretendardFont(family: .SemiBold, size: 52)
          .foregroundStyle(store.hasRemainingTimeResult ? .gray900 : .enableColor)
          .frame(height: 69)

        Text(HomeFeature.Strings.hours)
          .pretendardCustomFont(textStyle: .caption)
          .foregroundStyle(store.hasRemainingTimeResult ? .gray900 : .enableColor)

      }

      Spacer()
        .frame(width: 24)

      Image(asset: .time)
        .resizable()
        .scaledToFit()
        .frame(width: 6, height: 31)

      Spacer()
        .frame(width: 24)

      VStack {
        Text(store.remainingMinutesText)
          .pretendardFont(family: .SemiBold, size: 52)
          .foregroundStyle(store.hasRemainingTimeResult ? .gray900 : .enableColor)
          .frame(height: 69)

        Text(HomeFeature.Strings.minutes)
          .pretendardCustomFont(textStyle: .caption)
          .foregroundStyle(store.hasRemainingTimeResult ? .gray900 : .enableColor)

      }

      Spacer()

    }
    .padding(.vertical, 21)
    .background(
      RoundedRectangle(cornerRadius: Layout.TimeDisplay.cornerRadius)
        .fill(.white)
    )
    .padding(.horizontal, 24)
  }

  @ViewBuilder
  fileprivate func exploreNearbyButton() -> some View {
    CustomButton(
      action: {
        store.send(.view(.exploreNearbyButtonTapped))
      },
      title: HomeFeature.Strings.exploreNearby,
      config: CustomButtonConfig.create(),
      isEnable: store.isExploreNearbyEnabled
    )
    .padding(.horizontal, 24)
  }
}
