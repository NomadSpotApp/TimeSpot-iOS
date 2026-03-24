//
//  HomeReducer.swift
//  Home
//
//  Created by Wonji Suh  on 3/24/26.
//


import Foundation
import ComposableArchitecture
import Utill


@Reducer
public struct HomeReducer {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
    var departureTimePickerVisible: Bool = false
    var departureTime: Date = .now
    var currentTime: Date = .now
    var todayDate: Date = .now
    var isSelected: Bool = false
    var isDepartureTimeSet: Bool = false
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)

  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case departureTimeButtonTapped
    case departureTimeChanged(Date)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {

  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
  }

  //MARK: - NavigationAction
  public enum DelegateAction: Equatable {


  }


  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

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
  }
}

extension HomeReducer {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .departureTimeButtonTapped:
      state.departureTimePickerVisible.toggle()
      return .none

    case .departureTimeChanged(let date):
      state.currentTime = .now
      state.departureTime = date
      state.departureTimePickerVisible = false
      state.isDepartureTimeSet = true
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    return .none
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    return .none
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    return .none
  }
}

extension HomeReducer.State {
  var hasRemainingTimeResult: Bool {
    isDepartureTimeSet && !departureTimePickerVisible
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
extension HomeReducer.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(departureTimePickerVisible)
    hasher.combine(todayDate)
    hasher.combine(isSelected)
    hasher.combine(currentTime)
    hasher.combine(departureTime)
    hasher.combine(isDepartureTimeSet)
  }
}
