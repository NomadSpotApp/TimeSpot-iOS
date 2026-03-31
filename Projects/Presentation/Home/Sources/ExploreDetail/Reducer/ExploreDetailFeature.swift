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
    public var showLowStayTimeToast: Bool = false
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

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
    case visitUnavailable
    case networkError
  }

  @CasePathable
  public enum View {
    case onAppear
    case hideLowStayTimeToast
    case routeButtonTapped
  }

  public enum AsyncAction: Equatable {
    case fetchPlaceDetail
  }

  public enum InnerAction: Equatable {
    case fetchPlaceDetailResponse(Result<PlaceDetailEntity, PlaceError>)
  }

  public enum DelegateAction: Equatable {
    case presentRoute
  }

  @Dependency(\.placeUseCase) var placeUseCase

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

    case .hideLowStayTimeToast:
      state.showLowStayTimeToast = false
      return .none

    case .routeButtonTapped:
      // UserSession에 목적지 정보 저장
      if let placeDetail = state.placeDetail {
        state.$userSession.withLock { userSession in
          userSession.routeDestinationLat = placeDetail.latitude
          userSession.routeDestinationLng = placeDetail.longitude
          userSession.routeDestinationName = placeDetail.name
        }
      }

      return .send(.delegate(.presentRoute))
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
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case .customAlert(.presented(.confirmTapped)):
      switch state.customAlertMode {
      case .visitUnavailable, .networkError:
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
        if isVisitUnavailable(detail: detail, fetchedAt: state.userSession.explorePlacesFetchedAt) {
          state.customAlertMode = .visitUnavailable
          state.customAlert = .alert(
            title: "방문 불가능해요",
            message: "남은 체류 시간이 없어서 이전 화면으로 돌아갈게요.",
            confirmTitle: "확인",
            cancelTitle: "취소"
          )
        } else {
          // 체류시간이 10분 미만이면 토스트 표시
          let remainingMinutes = calculateRemainingStayableMinutes(detail: detail, fetchedAt: state.userSession.explorePlacesFetchedAt)
          if remainingMinutes > 0 && remainingMinutes < 10 {
            state.showLowStayTimeToast = true
          }
        }
      case .failure(let error):
        state.errorMessage = error.errorDescription
        state.customAlertMode = .networkError
        state.customAlert = .alert(
          title: "오류가 발생했어요",
          message: error.errorDescription ?? "장소 정보를 불러오지 못했어요.",
          confirmTitle: "확인",
          cancelTitle: "취소"
        )
      }
      return .none
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
      return "\(placeDetail.distanceFromStation)m"
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
      return CLLocationCoordinate2D(
        latitude: placeDetail.latitude,
        longitude: placeDetail.longitude
      )
    }

    return CLLocationCoordinate2D(
      latitude: userSession.travelStationLat ?? 37.5666805,
      longitude: userSession.travelStationLng ?? 126.9784147
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
