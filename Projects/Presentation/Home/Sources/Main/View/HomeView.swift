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
      ToastManager.shared.showWarning("대기 시간이 부족합니다 (최소 20분 필요)")
    }
  }
}



extension HomeView {

  @ViewBuilder
  fileprivate func logoContentView() -> some View {
    let heroHeight: CGFloat = 524

    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        ZStack(alignment: .top) {
          Image(asset: .homeLogo)
            .resizable()
            .scaledToFill()
            .frame(width: geometry.size.width, height: heroHeight, alignment: .top)
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
        .frame(width: geometry.size.width, height: heroHeight)
        .background(.clear)
        .clipShape(
          UnevenRoundedRectangle(
            cornerRadii: .init(
              bottomLeading: 40,
              bottomTrailing: 40
            )
          )
        )

        if store.departureTimePickerVisible {
          departureTimePickerView()
            .offset(x: geometry.size.width - 8 - 176 - 8, y: 492)
            .zIndex(2)
        }
      }
    }
    .frame(height: heroHeight)
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
        title: "현재 시간",
        time: store.currentTime.formattedKoreanTime(),
        timeColor: .gray900,
        backgroundColor: .gray100
      )

      Button {
        store.send(.view(.departureTimeButtonTapped))
      } label: {
        timeCapsuleView(
          title: "출발 시간",
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
      "출발 시간 선택",
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
    .frame(height: 180)
    .clipped()
    .frame(width: 176)
    .background(.gray300)
    .clipShape(RoundedRectangle(cornerRadius: 24))
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
    .frame(height: 77)
    .background(backgroundColor)
    .cornerRadius(28)
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

        Text("HOURS")
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

        Text("MINUTES")
          .pretendardCustomFont(textStyle: .caption)
          .foregroundStyle(store.hasRemainingTimeResult ? .gray900 : .enableColor)

      }

      Spacer()

    }
    .padding(.vertical, 21)
    .background(
      RoundedRectangle(cornerRadius: 36)
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
      title: "주변 탐색 시작하기",
      config: CustomButtonConfig.create(),
      isEnable: store.isExploreNearbyEnabled
    )
    .padding(.horizontal, 24)
  }
}
