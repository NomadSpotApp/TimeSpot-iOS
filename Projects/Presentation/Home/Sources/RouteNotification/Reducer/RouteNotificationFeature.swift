//
//  RouteNotificationFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/31/26.
//


import Foundation
import ComposableArchitecture
import CoreLocation
import UseCase


@Reducer
public struct RouteNotificationFeature {
  public init() {}

  @Dependency(\.getRouteUseCase) var getRouteUseCase

  @ObservableState
  public struct State: Equatable {
    public var notificationType: NotificationType = .now
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    @Shared(.appStorage("nearestStationLat")) var persistedStationLat: Double = 0.0
    @Shared(.appStorage("nearestStationLng")) var persistedStationLng: Double = 0.0

    public init(notificationType: NotificationType = .now) {
      self.notificationType = notificationType
    }
  }

  public enum NotificationType: Equatable, CaseIterable {
    case now        // 지금 바로 출발
    case fiveMin    // 5분 전
    case tenMin     // 10분 전
    case fifteenMin // 15분 전

    public var title: String {
      switch self {
      case .now:
        return "지금 바로 출발해야 해요!"
      case .fiveMin:
        return "5분 뒤면 역으로 출발 일어날 채비를 할 시간이에요."
      case .tenMin:
        return "10분 뒤면 역으로 출발해야 해요!"
      case .fifteenMin:
        return "역으로 출발하기까지 15분 남았어요!"
      }
    }

    public var subtitle: String {
      switch self {
      case .now:
        return "지금 바로 역으로 향해야 15분 전에 플랫폼에 도착할 수 있어요."
      case .fiveMin:
        return "잠시 후 출발할 수 있도록 미리 준비해주세요."
      case .tenMin:
        return "이제 슬슬 일어날 준비를 해볼까요?"
      case .fifteenMin:
        return "지금 하는 활동을 차분히 마무리해 주세요."
      }
    }

    public static func from(deepLink: String) -> NotificationType {
      guard let url = URL(string: deepLink) else {
        return .now
      }

      // URL host/path 체크 (timespot://departure_time 등)
      let pathComponents = url.pathComponents.filter { $0 != "/" }
      let hostOrPath = url.host ?? pathComponents.first ?? ""

      switch hostOrPath {
      case "departure_time":
        return .now
      case let path where path.contains("15_min_before"):
        return .fifteenMin
      case let path where path.contains("10_min_before"):
        return .tenMin
      case let path where path.contains("5_min_before"):
        return .fiveMin
      default:
        break
      }

      // URL에서 notificationType 파라미터 추출
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
         let notificationTypeParam = components.queryItems?.first(where: { $0.name == "notificationType" })?.value {

        switch notificationTypeParam {
        case "BEFORE_15_MINUTES":
          return .fifteenMin
        case "BEFORE_10_MINUTES":
          return .tenMin
        case "BEFORE_5_MINUTES":
          return .fiveMin
        case "DEPARTURE_TIME":
          return .now
        default:
          return .now
        }
      }

      // 기존 방식도 유지 (fallback)
      if deepLink.contains("15_min_before") {
        return .fifteenMin
      } else if deepLink.contains("10_min_before") {
        return .tenMin
      } else if deepLink.contains("5_min_before") {
        return .fiveMin
      } else {
        return .now
      }
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
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case startNavigationToStation
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
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
      return .send(.async(.startNavigationToStation))

    case .closeButtonTapped:
      return .send(.delegate(.closeNotification))
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

    }
  }
}

extension RouteNotificationFeature.State: Hashable {}

extension RouteNotificationFeature.State {
  public var formattedDepartureTime: String {
    guard let departureTime = userSession.departureTime else {
      return "출발 시간 미설정"
    }

    return "열차 시간: \(departureTime.formattedKoreanTime())"
  }
}
