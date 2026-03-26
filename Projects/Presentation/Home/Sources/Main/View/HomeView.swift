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
  private enum LayoutConstants {
    static let heroHeight: CGFloat = 524
    static let pickerWidth: CGFloat = 176
    static let pickerHeight: CGFloat = 180
    static let pickerOffset = UIOffset(horizontal: -184, vertical: 492)
    static let timeCapsuleHeight: CGFloat = 77
    static let cornerRadius: CGFloat = 28
    static let heroCornerRadius: CGFloat = 40
    static let timeLeftCornerRadius: CGFloat = 36
  }

  // MARK: - String Constants (준비: 향후 국제화용)
  private enum Strings {
    static let currentTime = "현재 시간"
    static let departureTime = "출발 시간"
    static let hours = "HOURS"
    static let minutes = "MINUTES"
    static let exploreNearby = "주변 탐색 시작하기"
    static let departureTimeSelection = "출발 시간 선택"
    static let insufficientWaitTime = "대기 시간이 부족합니다 (최소 20분 필요)"
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
      bottomPadding: 140
    )
    .onAppear {
      store.send(.view(.onAppear))
    }
    .onChange(of: store.shouldShowDepartureWarningToast) { _, shouldShow in
      guard shouldShow else { return }
      ToastManager.shared.showWarning(Strings.insufficientWaitTime)
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
            .frame(width: geometry.size.width, height: LayoutConstants.heroHeight, alignment: .top)
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
        .frame(width: geometry.size.width, height: LayoutConstants.heroHeight)
        .background(.clear)
        .clipShape(
          UnevenRoundedRectangle(
            cornerRadii: .init(
              bottomLeading: LayoutConstants.heroCornerRadius,
              bottomTrailing: LayoutConstants.heroCornerRadius
            )
          )
        )

        if store.departureTimePickerVisible {
          departureTimePickerView()
            .offset(x: geometry.size.width + LayoutConstants.pickerOffset.horizontal, y: LayoutConstants.pickerOffset.vertical)
            .zIndex(2)
        }
      }
    }
    .frame(height: LayoutConstants.heroHeight)
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
          .frame(width: 56, height: 56)
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

        Text(store.selectedStation.homeTitle)
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
        title: Strings.currentTime,
        time: store.currentTime.formattedKoreanTime(),
        timeColor: .gray900,
        backgroundColor: .gray100
      )

      Button {
        store.send(.view(.departureTimeButtonTapped))
      } label: {
        timeCapsuleView(
          title: Strings.departureTime,
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
      Strings.departureTimeSelection,
      selection: $store.departureTime,
      in: store.currentTime...,
      displayedComponents: [.hourAndMinute]
    )
    .datePickerStyle(.wheel)
    .labelsHidden()
    .environment(\.locale, Locale(identifier: "ko_KR"))
    .onChange(of: store.departureTime) { _, newValue in
      store.send(.view(.departureTimeChanged(newValue)))
    }
    .frame(height: LayoutConstants.pickerHeight)
    .clipped()
    .frame(width: LayoutConstants.pickerWidth)
    .background(.gray300)
    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius))
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
    .frame(height: LayoutConstants.timeCapsuleHeight)
    .background(backgroundColor)
    .cornerRadius(LayoutConstants.cornerRadius)
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

        Text(Strings.hours)
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

        Text(Strings.minutes)
          .pretendardCustomFont(textStyle: .caption)
          .foregroundStyle(store.hasRemainingTimeResult ? .gray900 : .enableColor)

      }

      Spacer()

    }
    .padding(.vertical, 21)
    .background(
      RoundedRectangle(cornerRadius: LayoutConstants.timeLeftCornerRadius)
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
      title: Strings.exploreNearby,
      config: CustomButtonConfig.create(),
      isEnable: store.isExploreNearbyEnabled
    )
    .padding(.horizontal, 24)
  }
}
