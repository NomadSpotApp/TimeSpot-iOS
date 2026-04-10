//
//  RouteNotificationFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/31/26.
//


import Foundation
import ComposableArchitecture
import CoreLocation
import Entity
import UseCase
import LogMacro

// MARK: - Journey Error
public enum JourneyEndError: Error, Equatable {
  case message(String)

  public var localizedDescription: String {
    switch self {
    case .message(let string):
      return string
    }
  }

  public static func from(_ error: Error) -> JourneyEndError {
    return .message(error.localizedDescription)
  }
}


@Reducer
public struct RouteNotificationFeature {
  public init() {}

  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.historyRepository) var historyRepository

  @ObservableState
  public struct State: Equatable {
    public var notificationType: NotificationType = .now
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    @Shared(.appStorage("nearestStationLat")) var persistedStationLat: Double = 0.0
    @Shared(.appStorage("nearestStationLng")) var persistedStationLng: Double = 0.0
    @Shared(.appStorage("visitingHistoryId")) var visitingHistoryId: Int = 0

    public init(notificationType: NotificationType = .now) {
      self.notificationType = notificationType
    }
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
    case backButtonTapped
    case departureButtonTapped
    case closeButtonTapped
    case onAppear
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case startNavigationToStation
    case endJourney(journeyId: Int, isCompleted: Bool)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case journeyEndResponse(Result<JourneyEntity, JourneyEndError>)
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case presentHome
    case presentRoute
    case closeNotification
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

        case .delegate(let delegateAction):
          return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension RouteNotificationFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backButtonTapped:
      return .send(.delegate(.presentHome))

    case .departureButtonTapped:
      #logDebug("🔔 RouteNotificationFeature: 역으로 출발하기 버튼 탭됨")
      return .concatenate(
        .send(.async(.startNavigationToStation)),
        .send(.delegate(.closeNotification))
      )

    case .closeButtonTapped:
      #logDebug("🔔 RouteNotificationFeature: 종료하기 버튼 탭됨")
      if state.notificationType == .endJourney {
        // 저장된 visitingHistoryId를 사용하여 여정 종료 API 호출
        let journeyId = state.visitingHistoryId
        guard journeyId > 0 else {
          #logDebug("❌ visitingHistoryId가 없습니다.")
          return .send(.delegate(.closeNotification))
        }
        return .send(.async(.endJourney(journeyId: journeyId, isCompleted: true)))
      } else {
        return .send(.delegate(.closeNotification))
      }

    case .onAppear:
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .startNavigationToStation:
      // appStorage에서 저장된 역 위치 확인
      let stationLat = state.persistedStationLat
      let stationLng = state.persistedStationLng

      guard stationLat != 0.0 && stationLng != 0.0 else {
        return .none
      }

      let destination = CLLocationCoordinate2D(latitude: stationLat, longitude: stationLng)
      let destinationName = state.userSession.travelStationName.isEmpty ? "역" : state.userSession.travelStationName

      // 기본 지도 앱 사용 (네이버맵 등)
      return .run { _ in
        await getRouteUseCase.startNavigation(
          mapType: .naverMap,
          destination: destination,
          destinationName: destinationName
        )
      }

    case .endJourney(let journeyId, let isCompleted):
      return .run { send in
        let result = await Result {
          try await historyRepository.endJourney(journeyId: journeyId, isCompleted: isCompleted)
        }
        .mapError(JourneyEndError.from)

        await send(.inner(.journeyEndResponse(result)))
      }
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .presentHome:
      return .none
    case .presentRoute:
      return .none
    case .closeNotification:
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .journeyEndResponse(let result):
      switch result {
      case .success(let journey):
        #logDebug("✅ 여정 종료 성공: \(journey.id)")

        // 여정 종료 성공 시 visitingHistoryId 초기화
        state.$visitingHistoryId.withLock { $0 = 0 }

        // 대기 중인 딥링크도 제거하여 앱 재시작 시 알림 화면이 나타나지 않도록 함
        UserDefaults.standard.removeObject(forKey: "pendingPushDeepLink")
        #logDebug("🗑️ 여정 종료 후 pendingPushDeepLink 제거 완료")

        // 알림 닫기
        return .send(.delegate(.closeNotification))
      case .failure(let error):
        #logDebug("❌ 여정 종료 실패: \(error.localizedDescription)")
        // TODO: 에러 처리 (토스트 메시지 등)
        return .none
      }
    }
  }
}


extension RouteNotificationFeature.State {
  public var formattedDepartureTime: String {
    guard let departureTime = userSession.departureTime else {
      return "출발 시간 미설정"
    }

    return "열차 시간: \(departureTime.formattedKoreanTime())"
  }
}

// MARK: - Equatable Extensions

extension RouteNotificationFeature.InnerAction {
  public static func == (lhs: RouteNotificationFeature.InnerAction, rhs: RouteNotificationFeature.InnerAction) -> Bool {
    switch (lhs, rhs) {
    case (.journeyEndResponse(.success(let lhsJourney)), .journeyEndResponse(.success(let rhsJourney))):
      return lhsJourney.id == rhsJourney.id
    case (.journeyEndResponse(.failure(let lhsError)), .journeyEndResponse(.failure(let rhsError))):
      return lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }
}

extension RouteNotificationFeature.AsyncAction {
  public static func == (lhs: RouteNotificationFeature.AsyncAction, rhs: RouteNotificationFeature.AsyncAction) -> Bool {
    switch (lhs, rhs) {
    case (.startNavigationToStation, .startNavigationToStation):
      return true
    case (.endJourney(let lhsId, let lhsCompleted), .endJourney(let rhsId, let rhsCompleted)):
      return lhsId == rhsId && lhsCompleted == rhsCompleted
    default:
      return false
    }
  }
}
