//
//  NotificationSettingFeature.swift
//  Profile
//
//  Created by Wonji Suh  on 3/26/26.
//


import Foundation
import ComposableArchitecture

import Utill
import Entity
import UseCase

@Reducer
public struct NotificationSettingFeature {
  public init() {}


  @ObservableState
  public struct State: Equatable {
    var selectedOptions: [NotificationOption] = []
    var isLoading: Bool = false

    public init() {}
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
    case onAppear
    case notificationOptionTapped(NotificationOption)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case fetchNotificationSettings
    case editNotificationSettings([NotificationOption])
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case fetchNotificationSettingsResponse(Result<NotificationEntity, ProfileError>)
    case editNotificationSettingsResponse(Result<NotificationEntity, ProfileError>)
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case presentBack

  }

  nonisolated enum CancelID: Hashable {
    case fetchCancel
    case editCancel
  }

  @Dependency(\.profileUseCase) var profileUseCase

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

        case .delegate(let delegateAction):
          return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension NotificationSettingFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      state.isLoading = true
      return .send(.async(.fetchNotificationSettings))

    case .notificationOptionTapped(let option):
      if option == .none {
        state.selectedOptions = [.none]
        return .send(.async(.editNotificationSettings([])))
      }

      guard option != .departureTime else {
        return .none
      }

      state.selectedOptions.removeAll { $0 == .none }

      if state.selectedOptions.contains(option) {
        state.selectedOptions.removeAll { $0 == option }
        if selectedEditableOptions(state: state).isEmpty {
          state.selectedOptions = [.none]
        }
        return .send(.async(.editNotificationSettings(selectedEditableOptions(state: state))))
      }

      guard selectedEditableOptions(state: state).count < 3 else {
        return .none
      }

      state.selectedOptions.append(option)
      return .send(.async(.editNotificationSettings(selectedEditableOptions(state: state))))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchNotificationSettings:
      return .run { send in
        let result = await Result {
          try await profileUseCase.fetchNotificationSettings()
        }
        .mapError(ProfileError.from)
        await send(.inner(.fetchNotificationSettingsResponse(result)))
      }
      .cancellable(id: CancelID.fetchCancel)

    case .editNotificationSettings(let notificationSettings):
      return .run { send in
        let result = await Result {
          try await profileUseCase.editNotificationSettings(
            notificationSettings: notificationSettings
          )
        }
        .mapError(ProfileError.from)
        await send(.inner(.editNotificationSettingsResponse(result)))
      }
      .cancellable(id: CancelID.editCancel, cancelInFlight: true)
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentBack:
        return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .fetchNotificationSettingsResponse(let result),
         .editNotificationSettingsResponse(let result):
      state.isLoading = false
      switch result {
      case .success(let entity):
        state.selectedOptions = makeSelectedOptions(entity: entity)
        return .none
      case .failure:
        return .none
      }
    }
  }
}

private extension NotificationSettingFeature {
  func selectedEditableOptions(state: State) -> [NotificationOption] {
    state.selectedOptions.filter {
      $0 != .none && $0 != .departureTime
    }
  }

  func makeSelectedOptions(entity: NotificationEntity) -> [NotificationOption] {
    let options: [NotificationOption] = entity.settings
      .filter(\.isEnabled)
      .map(\.option)
      .filter { $0 != .departureTime }

    if options.isEmpty {
      return [.none]
    }

    return options
  }
}


extension NotificationSettingFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(selectedOptions)
    hasher.combine(isLoading)
  }
}
