//
//  HomeReducer.swift
//  Home
//
//  Created by Wonji Suh  on 3/24/26.
//


import Foundation
import CoreLocation
import ComposableArchitecture
import DesignSystem
import DomainInterface
import Entity
import Utill


@Reducer
public struct HomeFeature {
  @Dependency(\.date.now) var now
  @Dependency(\.keychainManager) var keychainManager

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {
      let currentDate = Date()
      departureTime = currentDate
      currentTime = currentDate
      todayDate = currentDate
    }

    @Presents var customAlert: CustomAlertState<CustomAlertAction>?
    @Presents var trainStation: TrainStationFeature.State?
    var departureTimePickerVisible: Bool = false
    var departureTime: Date
    var currentTime: Date
    var todayDate: Date
    var isSelected: Bool = false
    var isDepartureTimeSet: Bool = false
    var selectedStation: Station = .seoul
    var hasSelectedStation: Bool = false
    var customAlertMode: CustomAlertMode? = nil
    var hasAppearedOnce: Bool = false
    var shouldResetAfterExplore: Bool = false
  }

  enum CustomAlertMode: Equatable, Hashable {
    case loginRequired
    case locationPermissionRequired
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case customAlert(PresentationAction<CustomAlertAction>)
    case trainStation(PresentationAction<TrainStationFeature.Action>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)

  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case onAppear
    case profileButtonTapped
    case selectStationButtonTapped
    case departureTimeButtonTapped
    case departureTimeChanged(Date)
    case exploreNearbyButtonTapped
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case checkProfileAccessToken
    case requestHomeLocationPermission
    case requestExploreLocationPermission
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case accessTokenCheckedForProfile(Bool)
    case showDepartureWarningToast
    case exploreLocationPermissionChecked(Bool)
    case resetAfterExploreIfNeeded
  }

  //MARK: - NavigationAction
  public enum DelegateAction: Equatable {
    case presentProfile
    case presentAuth
    case presentExplore

  }


  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .customAlert(let action):
        return handleCustomAlertAction(state: &state, action: action)

      case .trainStation(let action):
        return handleTrainStationAction(state: &state, action: action)

      case .view(let viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case .async(let asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case .inner(let innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case .delegate(let delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
    .ifLet(\.$trainStation, action: \.trainStation) {
      TrainStationFeature()
    }
  }
}

extension HomeFeature {
  private func handleCustomAlertAction(
    state: inout State,
    action: PresentationAction<CustomAlertAction>
  ) -> Effect<Action> {
    switch action {
    case .presented(.confirmTapped):
      switch state.customAlertMode {
      case .loginRequired:
        state.customAlert = nil
        state.customAlertMode = nil
        return .send(.delegate(.presentAuth))

      case .locationPermissionRequired:
        state.customAlert = nil
        state.customAlertMode = nil
        return .run { _ in
          await MainActor.run {
            LocationPermissionManager.shared.openLocationSettings()
          }
        }

      case .none:
        state.customAlert = nil
        return .none
      }

    case .presented(.cancelTapped), .dismiss:
      state.customAlert = nil
      state.customAlertMode = nil
      return .none

    case .presented(.policyTapped):
      return .none
    }
  }

  private func handleTrainStationAction(
    state: inout State,
    action: PresentationAction<TrainStationFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.stationSelected(let station))):
      state.selectedStation = station
      state.isSelected = false
      state.hasSelectedStation = true
      state.trainStation = nil
      guard state.shouldShowDepartureWarningToast else {
        return .none
      }
      return .send(.inner(.showDepartureWarningToast))

    case .dismiss:
      state.isSelected = false
      return .none

    default:
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .merge(
        .send(.async(.requestHomeLocationPermission)),
        .send(.inner(.resetAfterExploreIfNeeded))
      )

    case .profileButtonTapped:
      return .send(.async(.checkProfileAccessToken))

    case .selectStationButtonTapped:
      state.isSelected = true
      state.trainStation = .init(selectedStation: state.selectedStation)
      return .none

    case .departureTimeButtonTapped:
      state.departureTimePickerVisible.toggle()
      return .none

    case .departureTimeChanged(let date):
      state.currentTime = now
      state.departureTime = date
      state.departureTimePickerVisible = false
      state.isDepartureTimeSet = true
      guard state.shouldShowDepartureWarningToast else {
        return .none
      }
      return .send(.inner(.showDepartureWarningToast))

    case .exploreNearbyButtonTapped:
      guard state.isExploreNearbyEnabled else {
        return .none
      }
      return .send(.async(.requestExploreLocationPermission))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .checkProfileAccessToken:
      return .run { [keychainManager] send in
        let accessToken = await keychainManager.accessToken()
        let hasAccessToken = !(accessToken?.isEmpty ?? true)
        await send(.inner(.accessTokenCheckedForProfile(hasAccessToken)))
      }

    case .requestHomeLocationPermission:
      return .run { _ in
        let locationManager = await LocationPermissionManager.shared
        let currentStatus = await locationManager.authorizationStatus

        guard currentStatus == .notDetermined else { return }

        _ = await locationManager.requestLocationPermission()
      }

    case .requestExploreLocationPermission:
      return .run { send in
        let locationManager = await LocationPermissionManager.shared
        let status = await locationManager.requestLocationPermission()
        let isGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        await send(.inner(.exploreLocationPermissionChecked(isGranted)))
      }
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentProfile:
        return .none

      case .presentAuth:
        return .none

      case .presentExplore:
        return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .accessTokenCheckedForProfile(let hasAccessToken):
      guard hasAccessToken else {
        state.customAlertMode = .loginRequired
        state.customAlert = .alert(
          title: "로그인 해주세요",
          message: "로그인 후 프로필을 확인할 수 있어요.",
          confirmTitle: "확인",
          cancelTitle: "취소",
          isDestructive: false
        )
        return .none
      }
      return .send(.delegate(.presentProfile))

    case .showDepartureWarningToast:
      return .run { _ in
        await MainActor.run {
          ToastManager.shared.showWarning("대기 시간이 부족합니다 (최소 20분 필요)")
        }
      }

    case .exploreLocationPermissionChecked(let isGranted):
      guard isGranted else {
        state.customAlertMode = .locationPermissionRequired
        state.customAlert = .alert(
          title: "위치 권한이 필요합니다",
          message: "주변 탐색을 사용하려면 위치 권한을 허용해주세요.",
          confirmTitle: "설정",
          cancelTitle: "취소",
          isDestructive: false
        )
        return .none
      }
      state.shouldResetAfterExplore = true
      return .send(.delegate(.presentExplore))

    case .resetAfterExploreIfNeeded:
      if !state.hasAppearedOnce {
        state.hasAppearedOnce = true
        return .none
      }

      guard state.shouldResetAfterExplore else {
        return .none
      }

      let currentDate = now
      state.shouldResetAfterExplore = false
      state.departureTimePickerVisible = false
      state.departureTime = currentDate
      state.currentTime = currentDate
      state.todayDate = currentDate
      state.isSelected = false
      state.isDepartureTimeSet = false
      state.selectedStation = .seoul
      state.hasSelectedStation = false
      return .none
    }
  }
}

extension HomeFeature.State {
  var remainingTotalMinutes: Int {
    (remainingTime.hour ?? 0) * 60 + (remainingTime.minute ?? 0)
  }

  var isStationReady: Bool {
    hasSelectedStation || selectedStation == .seoul
  }

  var isExploreNearbyEnabled: Bool {
    isStationReady && isDepartureTimeSet && remainingTotalMinutes > 20
  }

  var hasRemainingTimeResult: Bool {
    isDepartureTimeSet && !departureTimePickerVisible
  }

  var shouldShowDepartureWarningToast: Bool {
    guard isStationReady && isDepartureTimeSet else {
      return false
    }

    return remainingTotalMinutes <= 20
  }

  var remainingTime: DateComponents {
    guard isDepartureTimeSet else {
      return DateComponents(hour: 0, minute: 0)
    }

    return Calendar.current.remainingTimeComponents(from: currentTime, to: departureTime)
  }

  var remainingHoursText: String {
    String(format: "%02d", remainingTime.hour ?? 0)
  }

  var remainingMinutesText: String {
    String(format: "%02d", remainingTime.minute ?? 0)
  }
}

// MARK: - HomeReducer.State + Hashable
extension HomeFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(trainStation)
    hasher.combine(departureTimePickerVisible)
    hasher.combine(todayDate)
    hasher.combine(isSelected)
    hasher.combine(hasSelectedStation)
    hasher.combine(currentTime)
    hasher.combine(departureTime)
    hasher.combine(isDepartureTimeSet)
    hasher.combine(selectedStation)
    hasher.combine(customAlertMode)
    hasher.combine(hasAppearedOnce)
    hasher.combine(shouldResetAfterExplore)
  }
}
