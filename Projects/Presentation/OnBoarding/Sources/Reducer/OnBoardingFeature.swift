//
//  OnBoardingFeature.swift
//  OnBoarding
//
//  Created by Wonji Suh  on 3/21/26.
//

import Foundation
import ComposableArchitecture

import UseCase
import Entity

@Reducer
public struct OnBoardingFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable, Hashable {

    public init() {}
    var stepRange: ClosedRange<Int> = 1...4
    var activeStep: Int = 1
    var selectedMap: ExternalMapType? = nil
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)

  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case nextStepButtonTapped
    case mapSelected(ExternalMapType)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {

  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
  }

  //MARK: - NavigationAction
  public enum NavigationAction: Equatable {
    case onBoardingCompleted
  }


  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding(_):
          return .none

        case .view(let viewAction):
          return handleViewAction(state: &state, action: viewAction)

        case .async(let asyncAction):
          return handleAsyncAction(state: &state, action: asyncAction)

        case .inner(let innerAction):
          return handleInnerAction(state: &state, action: innerAction)

        case .navigation(let navigationAction):
          return handleNavigationAction(state: &state, action: navigationAction)
      }
    }
  }
}

extension OnBoardingFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .nextStepButtonTapped:
      if state.activeStep >= state.stepRange.upperBound {
        return .send(.navigation(.onBoardingCompleted))
      }
      state.activeStep += 1
      return .none

    case .mapSelected(let mapType):
      state.selectedMap = state.selectedMap == mapType ? nil : mapType
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {

    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
    case .onBoardingCompleted:
      // Coordinator에서 처리
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {

    }
  }
}

