//
//  HomeCoordinator.swift
//  Home
//
//  Created by Wonji Suh  on 3/24/26.
//

import ComposableArchitecture
import TCAFlow
import Profile
import CoreLocation
import Entity
import UseCase
import LogMacro

@Reducer
public struct HomeCoordinator {

  public init(){}

  @ObservableState
  public struct State: Equatable {
    var routes: [Route<HomeScreen.State>]

    public init() {
      self.routes = [.root(.home(.init()), embedInNavigationView: true)]
    }

    // 푸쉬 알림용 이니셜라이저
    public init(withRouteNotification: Bool, deepLink: String? = nil) {
      if withRouteNotification, let deepLink = deepLink {
        // 딥링크에 따른 알림 타입 결정
        let notificationType = NotificationType.from(deepLink: deepLink)

        // 홈을 root로 하고 RouteNotificationView를 즉시 push (스와이프 뒤로가기 지원)
        self.routes = [
          .root(.home(.init()), embedInNavigationView: true),
          .push(.routeNotification(.init(notificationType: notificationType)))
        ]
      } else {
        self.routes = [.root(.home(.init()), embedInNavigationView: true)]
      }
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<HomeScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }

  // MARK: - ViewAction
  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  // MARK: - AsyncAction 비동기 처리 액션

  public enum AsyncAction: Equatable {

  }

  // MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case presentProfile
    case presentExplore
    case presentExploreList(ExploreFeature.State)
    case presentExploreDetail
    case presentRouteFromPushNotification(String)
  }

  // MARK: - NavigationAction
  public enum NavigationAction: Equatable {
    case presentAuth

  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        case .router(let routeAction):
          return routerAction(state: &state, action: routeAction)

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
    .forEachRoute(\.routes, action: \.router)
  }

}

extension HomeCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<HomeScreen>
  ) -> Effect<Action> {
    switch action {
      case .routeAction(id: _, action: .home(.delegate(.presentProfile))):
        state.routes.push(.profile(.init()))
        return .none

      case .routeAction(id: _, action: .home(.delegate(.presentExplore))):
        return .send(.inner(.presentExplore))

      case .routeAction(id: _, action: .home(.delegate(.presentAuth))):
        return .send(.navigation(.presentAuth))

      case let .routeAction(id: id, action: .explore(.delegate(.presentExploreList))):
        guard state.routes.indices.contains(id) else {
          return .none
        }

        switch state.routes[id] {
        case let .push(.explore(exploreState)):
          return .send(.inner(.presentExploreList(exploreState)))
        default:
          return .none
        }

      case let .routeAction(id: id, action: .explore(.delegate(.presentExplorerDetail))):
        guard state.routes.indices.contains(id) else {
          return .none
        }

        switch state.routes[id] {
        case .push(.explore):
          return .send(.inner(.presentExploreDetail))
        default:
          return .none
        }

      case let .routeAction(id: id, action: .exploreList(.delegate(.presentExploreMapAtCurrentLocation))):
        guard state.routes.indices.contains(id) else {
          return .none
        }

        let exploreIndex = id - 1
        guard exploreIndex >= 0,
              state.routes.indices.contains(exploreIndex) else {
          return .send(.view(.backAction))
        }

        switch state.routes[exploreIndex] {
        case .push(.explore):
          state.routes.goBack()
          return .send(
            .router(
              .routeAction(
                id: exploreIndex,
                action: .explore(.view(.returnToCurrentLocation))
              )
            )
          )

        default:
          return .send(.view(.backAction))
        }

      case .routeAction(id: _, action: .exploreList(.delegate(.presentExploreDetail))):
        return .send(.inner(.presentExploreDetail))

      case .routeAction(id: _, action: .profile(.navigation(.presentRoot))):
        return .send(.view(.backAction))

      case .routeAction(id: _, action: .profile(.navigation(.presentAuth))):
        return .send(.navigation(.presentAuth))

      case .routeAction(id: _, action: .explore(.delegate(.presentRoute))):
        state.routes.push(.route(.init()))
        return .none

      case .routeAction(id: _, action: .exploreDetail(.delegate(.presentRoute))):
        state.routes.push(.route(.init()))
        return .none

      case .routeAction(id: _, action: .exploreDetail(.delegate(.presentExploreMapAtCurrentLocation))):
        return routeWithDelaysIfUnsupported(state.routes, action: \.router) {
          $0.goBackTo(\.explore)
        }

      case .routeAction(id: _, action: .routeNotification(.delegate(.presentRoute))):
        state.routes.push(.route(.init()))
        return .none

      case .routeAction(id: _, action: .routeNotification(.delegate(.closeNotification))):
        return .send(.view(.backAction))

      case .routeAction(id: _, action: .routeNotification(.delegate(.presentHome))):
        return .send(.view(.backAction))

      default:
        return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .backAction:
        state.routes.goBack()
        return .none

      case .backToRootAction:
        state.routes.goBackToRoot()
        return .none
    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
      case .presentAuth:
        return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    default:
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .presentProfile:
      state.routes.push(.profile(.init()))
      return .none

    case .presentExplore:
      var exploreState = ExploreFeature.State()
      if let lat = exploreState.userSession.travelStationLat,
         let lng = exploreState.userSession.travelStationLng {
        exploreState.selectedDestination = Destination(
          name: exploreState.userSession.travelStationName,
          coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
        )
      }
      state.routes.push(.explore(exploreState))
      return .none

    case let .presentExploreList(exploreState):
      var exploreListState = ExploreListFeature.State()
      exploreListState.searchText = exploreState.searchText
      exploreListState.selectedCategory = exploreState.selectedCategory
      exploreListState.currentLocation = exploreState.currentLocation?.coordinate
      exploreListState.markerLat = exploreState.mapCenterLat ?? exploreState.searchMarkerLat
      exploreListState.markerLon = exploreState.mapCenterLon ?? exploreState.searchMarkerLon

      let hasFullyLoadedMarkerData =
        !exploreState.spots.isEmpty
        && exploreState.spots.allSatisfy(\.hasDetail)

      if hasFullyLoadedMarkerData {
        exploreListState.bufferedSpots = exploreState.spots
        exploreListState.spots = Array(
          exploreState.spots.prefix(ExploreListFeature.State.pageChunkSize)
        )
        exploreListState.currentPage = exploreState.currentPage
        exploreListState.hasNextPage = exploreState.hasNextPage
        exploreListState.hasLoadedInitialPage = true
      }

      state.routes.push(.exploreList(exploreListState))
      return .none

    case .presentExploreDetail:
      state.routes.push(.exploreDetail(.init()))
      return .none

    case let .presentRouteFromPushNotification(deepLink):
      #logDebug("🚀 HomeCoordinator: presentRouteFromPushNotification 액션 처리 시작")

      let notificationType = NotificationType.from(deepLink: deepLink)
      #logDebug("📋 HomeCoordinator: 딥링크 = \(deepLink), 알림 타입 = \(notificationType)")

      // 현재 routes 상태 로그
      #logDebug("📍 현재 routes 개수: \(state.routes.count)")
      for (index, route) in state.routes.enumerated() {
        switch route.screen {
        case .home:
          #logDebug("Route[\(index)]: home")
        case .explore:
          #logDebug("Route[\(index)]: explore")
        case .exploreList:
          #logDebug("Route[\(index)]: exploreList")
        case .exploreDetail:
          #logDebug("Route[\(index)]: exploreDetail")
        case .profile:
          #logDebug("Route[\(index)]: profile")
        case .route:
          #logDebug("Route[\(index)]: route (기존)")
        case .routeNotification:
          #logDebug("Route[\(index)]: routeNotification (기존)")
        }
      }

      // 기존 route 또는 routeNotification 화면이 있으면 제거하고 새로 추가
      let removedCount = state.routes.count
      state.routes.removeAll { route in
        switch route.screen {
        case .route, .routeNotification:
          return true
        default:
          return false
        }
      }
      #logDebug("🗑️ 기존 route/routeNotification 화면 제거됨. 제거 전: \(removedCount), 제거 후: \(state.routes.count)")

      state.routes.push(.routeNotification(.init(notificationType: notificationType)))
      #logDebug("✅ RouteNotificationView 추가 완료. 현재 routes 개수: \(state.routes.count)")
      return .none
    }
  }

}

extension HomeCoordinator {
  @Reducer
  public enum HomeScreen {
    case home(HomeFeature)
    case explore(ExploreFeature)
    case exploreList(ExploreListFeature)
    case exploreDetail(ExploreDetailFeature)
    case profile(ProfileCoordinator)
    case route(RouteFeature)
    case routeNotification(RouteNotificationFeature)
  }
}

// MARK: - HomeScreen State Equatable
extension HomeCoordinator.HomeScreen.State: Equatable {}
