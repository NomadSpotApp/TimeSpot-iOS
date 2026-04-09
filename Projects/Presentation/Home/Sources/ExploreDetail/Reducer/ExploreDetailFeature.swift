//
//  ExploreDetailFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import ComposableArchitecture
import DesignSystem
import Entity
import UseCase
import Utill
import MapKit
import LogMacro

@Reducer
public struct ExploreDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var placeDetail: PlaceDetailEntity?
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var shouldDismiss: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    public var customAlertMode: CustomAlertMode?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

    // 스크롤 관련 상태
    public var scrollOffset: CGFloat = 0
    public var showNavigationTitle: Bool = false

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum ScopeAction {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum CustomAlertMode: Equatable {
    case networkError
  }

  @CasePathable
  public enum View {
    case onAppear
    case routeButtonTapped
    case titlePositionChanged(CGFloat)
  }

  public enum AsyncAction: Equatable {
    case fetchPlaceDetail
  }

  public enum InnerAction: Equatable {
    case fetchPlaceDetailResponse(Result<PlaceDetailEntity, PlaceError>)
  }

  public enum DelegateAction: Equatable {
    case presentRoute
    case presentExploreMapAtCurrentLocation
  }

  @Dependency(\.placeUseCase) var placeUseCase
  @Dependency(\.analyticsUseCase) var analyticsUseCase

  public var body: some Reducer<State, Action> {
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
      case .scope(let scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)
      case .delegate(let delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension ExploreDetailFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .send(.async(.fetchPlaceDetail))

    case .routeButtonTapped:
      // UserSession에 목적지 정보 저장
      if let placeDetail = state.placeDetail {
        analyticsUseCase.track(
          .place(
            .routeStarted,
            PlaceEventData(
              placeID: placeDetail.placeId,
              placeName: placeDetail.name,
              category: placeDetail.category,
              placeType: placeDetail.placeType
            )
          )
        )
        state.$userSession.withLock { userSession in
          userSession.routeDestinationLat = placeDetail.latitude
          userSession.routeDestinationLng = placeDetail.longitude
          userSession.routeDestinationName = placeDetail.name
        }
      }

      return .send(.delegate(.presentRoute))

    case .titlePositionChanged(let imageY):
      // 이미지가 조금만 스크롤되어도 네비게이션 바에 제목 표시
      // 더 빠른 트리거로 사용자 경험 개선
      state.showNavigationTitle = imageY < 120
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchPlaceDetail:
      guard let placeID = Int(state.userSession.selectedExplorePlaceID) else {
        state.errorMessage = PlaceError.placeNotFound.errorDescription
        return .none
      }

      state.isLoading = true
      state.errorMessage = nil
      let userSession = state.userSession

      return .run { send in
        let result = await Result {
          try await placeUseCase.detailPlace(
            userSession: userSession,
            placeId: placeID
          )
        }
        .mapError(PlaceError.from)

        await send(.inner(.fetchPlaceDetailResponse(result)))
      }
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .presentRoute:
      // 장소 상세 정보의 위도와 경도를 UserSession에 저장
      if let placeDetail = state.placeDetail {
        state.$userSession.withLock {
          // 목적지 정보 저장
          $0.routeDestinationLat = placeDetail.latitude
          $0.routeDestinationLng = placeDetail.longitude
          $0.routeDestinationName = placeDetail.name
        }
      }
      return .none
    case .presentExploreMapAtCurrentLocation:
      return .none
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case .customAlert(.presented(.confirmTapped)):
      switch state.customAlertMode {
      case .networkError:
        state.customAlert = nil
        state.customAlertMode = nil
        state.shouldDismiss = true
        return .none
      case .none:
        state.customAlert = nil
        return .none
      }

    case .customAlert(.presented(.cancelTapped)), .customAlert(.dismiss):
      state.customAlert = nil
      state.customAlertMode = nil
      return .none

    case .customAlert(.presented(.policyTapped)):
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .fetchPlaceDetailResponse(let result):
      state.isLoading = false

      switch result {
      case .success(let detail):
        state.placeDetail = detail
        state.errorMessage = nil
        analyticsUseCase.track(
          .place(
            .detailViewed,
            PlaceEventData(
              placeID: detail.placeId,
              placeName: detail.name,
              category: detail.category,
              placeType: detail.placeType,
              stayableMinutes: detail.stayableMinutes,
              walkTimeFromStation: detail.walkTimeFromStation,
              visitable: detail.visitable
            )
          )
        )

        let remainingMinutes = calculateRemainingStayableMinutes(detail: detail, fetchedAt: state.userSession.explorePlacesFetchedAt)

        // 체류시간에 따라 토스트 표시 (팝업 제거)
        if remainingMinutes <= 0 {
          return .run { _ in
            await MainActor.run {
              ToastManager.shared.showWarning("시간 부족으로 장소 방문이 불가해요")
            }
          }
        } else if remainingMinutes < 10 {
          return .run { _ in
            await MainActor.run {
              ToastManager.shared.showWarning("시간 부족으로 장소 방문이 불가해요")
            }
          }
        }
        return .none

      case .failure(let error):
        state.errorMessage = error.errorDescription
        return .run { _ in
          await MainActor.run {
            ToastManager.shared.showWarning("시간 부족으로 장소 방문이 불가해요")
          }
        }
      }
    }
  }

  private func isVisitUnavailable(
    detail: PlaceDetailEntity,
    fetchedAt: Date?
  ) -> Bool {
    let elapsedMinutes: Int
    if let fetchedAt {
      elapsedMinutes = max(Int(Date().timeIntervalSince(fetchedAt) / 60), 0)
    } else {
      elapsedMinutes = 0
    }
    return max(detail.stayableMinutes - elapsedMinutes, 0) <= 0
  }

  private func calculateRemainingStayableMinutes(
    detail: PlaceDetailEntity,
    fetchedAt: Date?
  ) -> Int {
    let elapsedMinutes: Int
    if let fetchedAt {
      elapsedMinutes = max(Int(Date().timeIntervalSince(fetchedAt) / 60), 0)
    } else {
      elapsedMinutes = 0
    }
    return max(detail.stayableMinutes - elapsedMinutes, 0)
  }
}

extension ExploreDetailFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(placeDetail)
    hasher.combine(isLoading)
    hasher.combine(errorMessage)
    hasher.combine(userSession)
  }
}

// MARK: - State Computed Properties
extension ExploreDetailFeature.State {

  var imageCards: [URL?] {
    let urls = placeDetail?.images.compactMap { urlString -> URL? in
      // Google Places API URL에 대한 특별한 처리
      if urlString.contains("places.googleapis.com") {
        return URL(string: urlString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
      }
      return urlString.normalizedURL
    } ?? []

    if !urls.isEmpty {
      return urls
    }
    return [nil, nil]
  }

  var placeNameText: String {
    placeDetail?.name ?? ""
  }

  var categoryText: String {
    placeDetail?.category ?? ""
  }

  var distanceText: String {
    if let placeDetail = placeDetail {
      return placeDetail.distanceFromStation.formattedDistance
    }
    return ""
  }

  var returnDeadlineText: String {
    if isVisitUnavailable {
      return "방문 불가능해요"
    }

    if let leaveTime = placeDetail?.leaveTime,
       let formatted = formattedDeadlineTime(from: leaveTime) {
      return formatted
    }

    return Date().formattedReturnDeadlineText(addingMinutes: stayableMinutesValue) + "분"
  }

  var stayableMinutesValue: Int {
    remainingStayableMinutes
  }

  var remainingStayableMinutes: Int {
    let originalMinutes = placeDetail?.stayableMinutes ?? 0
    let elapsedMinutes = elapsedMinutesSincePlacesFetched
    return max(originalMinutes - elapsedMinutes, 0)
  }

  var elapsedMinutesSincePlacesFetched: Int {
    guard let fetchedAt = userSession.explorePlacesFetchedAt else {
      return 0
    }

    return max(Int(Date().timeIntervalSince(fetchedAt) / 60), 0)
  }

  var isVisitUnavailable: Bool {
    guard let detail = placeDetail else { return true }
    return !detail.visitable
  }

  var returnDeadlineSuffixText: String {
    isVisitUnavailable ? "" : " 에는 역으로 출발해야 합니다."
  }

  var openingHoursText: String {
    if let useTime = placeDetail?.useTime, !useTime.isEmpty {
      // HTML 태그 제거 및 개행 문자 처리
      return useTime
        .replacingOccurrences(of: "<br>", with: "\n")
        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return "영업 시간 정보 준비 중"
  }

  var phoneNumberText: String {
    "전화번호 정보 준비 중"
  }

  var addressText: String {
    placeDetail?.address.nilIfEmpty ?? "주소 정보 준비 중"
  }

  var stayableMinutesText: String {
    "약 \(remainingStayableMinutes)분"
  }

  var walkMinutesText: String {
    if let placeDetail = placeDetail {
      return "\(placeDetail.walkTimeFromStation)분"
    }
    return "0분"
  }

  var mapCoordinate: CLLocationCoordinate2D {
    if let placeDetail = placeDetail {
      let coordinate = CLLocationCoordinate2D(
        latitude: placeDetail.latitude,   // 장소의 실제 위도
        longitude: placeDetail.longitude  // 장소의 실제 경도
      )

      // 디버깅: 좌표가 유효한지 확인
      if coordinate.latitude != 0 && coordinate.longitude != 0 {
        return coordinate
      }
    }

    // placeDetail이 없거나 좌표가 유효하지 않을 때는 기본 서울 중심 좌표 사용
    return CLLocationCoordinate2D(
      latitude: 37.5666805,  // 서울 중심
      longitude: 126.9784147
    )
  }

  var mapRegion: MKCoordinateRegion {
    MKCoordinateRegion(
      center: mapCoordinate,
      span: MKCoordinateSpan(latitudeDelta: 0.0035, longitudeDelta: 0.0035)
    )
  }

  // MARK: - Private Helper Methods

  private func summarizedOpeningHours(from values: [String]) -> String {
    let normalized = values
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    guard !normalized.isEmpty else {
      return ""
    }

    let extractedTimes = normalized.map { value in
      guard let separatorIndex = value.firstIndex(of: ":") else {
        return value
      }
      return value[value.index(after: separatorIndex)...]
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    let uniqueTimes = Array(Set(extractedTimes))

    if uniqueTimes.count == 1, let first = extractedTimes.first {
      return first
    }

    return normalized.joined(separator: ", ")
  }

  private func formattedDeadlineTime(from leaveTime: String) -> String? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    guard let date = formatter.date(from: leaveTime) else {
      return nil
    }

    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "ko_KR")
    outputFormatter.dateFormat = "a h:mm분"
    return outputFormatter.string(from: date)
  }
}
