//
//  ExploreDetailView.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//


import SwiftUI
import MapKit
import DesignSystem
import Kingfisher
import Entity
import Utill

import ComposableArchitecture

public struct ExploreDetailView: View {
  @Bindable var store: StoreOf<ExploreDetailFeature>
  @Environment(\.dismiss) private var dismiss

  public init(
    store: StoreOf<ExploreDetailFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        Color.gray100
          .edgesIgnoringSafeArea(.all)

        VStack {
          if !(store.isLoading && store.placeDetail == nil) {
            CustomNavigationBackBar(buttonAction: {
              dismiss()
            }, title: "")
            .padding(.horizontal, 16)
            .offset(y: -30)
          } else {
            Spacer()
              .frame(height: 24)
          }

          ScrollView(.vertical) {
            Group {
              if store.isLoading && store.placeDetail == nil {
                skeletonContent()
              } else {
                VStack(alignment: .leading) {
                  exploreSpotNameTitle()

                  imageSection()
                    .padding(.top, 24)

                  stayInfoSection()
                    .padding(.top, 24)

                  returnDeadlineSection()
                    .padding(.top, 24)

                  placeInfoSection()
                    .padding(.top, 29)

                  locationMapSection()
                    .padding(.top, 24)

                  routeButtonSection()
                    .padding(.top, 24)
                }
              }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
          }
          .scrollIndicators(.hidden)
        }

      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}


private extension ExploreDetailView {

  @ViewBuilder
  func exploreSpotNameTitle() -> some View {
    VStack(alignment: .leading) {
      Spacer()
        .frame(height: 4)

      HStack(spacing: 8) {
        Text(placeNameText.formattedPlaceNameForDisplay)
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.staticBlack)
          .lineLimit(2)

        Text(categoryText)
          .pretendardCustomFont(textStyle: .body2Regular)
          .foregroundStyle(.gray700)

        Spacer()
      }
    }
  }

  @ViewBuilder
  func imageSection() -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(imageCards.indices, id: \.self) { index in
          spotImageCard(for: imageCards[index], index: index)
        }
      }
    }
  }

  @ViewBuilder
  func stayInfoSection() -> some View {
    HStack(spacing: 0) {
      metricColumn(
        value: stayableMinutesText,
        title: "체류시간",
        valueColor: .orange800
      )

      divider

      metricColumn(
        value: walkMinutesText,
        title: "도보",
        valueColor: .gray830
      )

      divider

      metricColumn(
        value: distanceText,
        title: "거리",
        valueColor: .gray830
      )
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 16)
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(.gray300, lineWidth: 1)
    }
  }

  @ViewBuilder
  func returnDeadlineSection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 12) {
        Image(asset: .warning)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)
          .padding(.vertical,11)

        VStack(alignment: .leading,  spacing: 4) {
          HStack {
            Text("최종 복귀 시간")
              .pretendardCustomFont(textStyle: .body2Bold)
              .foregroundStyle(.gray700)

            Spacer()
          }

          (
            Text(returnDeadlineText)
              .foregroundStyle(isVisitUnavailable ? .gray700 : .orange800)
            +
            Text(returnDeadlineSuffixText).foregroundStyle(.gray800)
          )
          .pretendardCustomFont(textStyle: .body2Medium)
          .lineSpacing(2)
          .lineLimit(3)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
        }
      }


    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 21)
    .padding(.vertical, 18)
    .background(.orange200)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .overlay {
      RoundedRectangle(cornerRadius: 20)
        .stroke(.orange500, lineWidth: 1)
    }
  }

  @ViewBuilder
  func placeInfoSection() -> some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("장소 정보")
        .pretendardCustomFont(textStyle: .bodyBold)
        .foregroundStyle(.gray850)

      VStack(alignment: .leading, spacing: 16) {
        infoRow(
          icon: "clock.fill",
          title: "영업 시간",
          content: openingHoursText
        )

        infoRow(
          icon: "phone.fill",
          title: "전화번호",
          content: phoneNumberText
        )

        infoRow(
          icon: "location.fill",
          title: "주소",
          content: addressText
        )
      }
    }
  }

  @ViewBuilder
  func locationMapSection() -> some View {
    GeometryReader { proxy in
      Map(initialPosition: .region(mapRegion), interactionModes: .all) {
        Annotation(placeNameText, coordinate: mapCoordinate) {
          Image(asset: .spotPin)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 28)
        }
      }
      .frame(width: proxy.size.width, height: 180)
      .clipShape(RoundedRectangle(cornerRadius: 20))
      .clipped()
    }
    .frame(height: 180)
  }

  @ViewBuilder
  func routeButtonSection() -> some View {
    CustomButton(
      action: {},
      title: isVisitUnavailable ? "방문 불가능" : "경로 확인하기",
      config: CustomButtonConfig.create(),
      isEnable: !isVisitUnavailable
    )
  }

  @ViewBuilder
  func infoRow(
    icon: String,
    title: String,
    content: String
  ) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.gray700)
        .frame(width: 20, height: 20)
        .padding(.top, 1)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .pretendardCustomFont(textStyle: .body2Medium)
          .foregroundStyle(.gray700)

        Text(content)
          .pretendardCustomFont(textStyle: .bodyRegular)
          .foregroundStyle(.gray850)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  func metricColumn(
    value: String,
    title: String,
    valueColor: Color
  ) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .pretendardCustomFont(textStyle: .bodyMedium)
        .foregroundStyle(valueColor)

      Text(title)
        .pretendardCustomFont(textStyle: .body2Regular)
        .foregroundStyle(.gray800)
    }
    .frame(maxWidth: .infinity)
  }

  var divider: some View {
    Rectangle()
      .fill(.gray300)
      .frame(width: 1, height: 34)
  }

  var stayableMinutesText: String {
    "약 \(remainingStayableMinutes)분"
  }

  var walkMinutesText: String {
    if let placeDetail = store.placeDetail {
      return "\(placeDetail.timeToStation)분"
    }
    return "0분"
  }

  var imageCards: [URL?] {
    let urls = store.placeDetail?.imageURL.compactMap(\.normalizedURL) ?? []
    if !urls.isEmpty {
      return urls
    }
    return [nil, nil]
  }

  var placeNameText: String {
    store.placeDetail?.name ?? ""
  }

  var categoryText: String {
    store.placeDetail?.category ?? ""
  }

  var distanceText: String {
    if let placeDetail = store.placeDetail {
      return "\(placeDetail.distanceToStation)m"
    }
    return ""
  }

  var returnDeadlineText: String {
    if isVisitUnavailable {
      return "방문 불가능해요"
    }

    if let leaveTime = store.placeDetail?.leaveTime,
       let formatted = formattedDeadlineTime(from: leaveTime) {
      return formatted
    }

    return Date().formattedReturnDeadlineText(addingMinutes: stayableMinutesValue) + "분"
  }

  var stayableMinutesValue: Int {
    remainingStayableMinutes
  }

  var remainingStayableMinutes: Int {
    let originalMinutes = store.placeDetail?.stayableMinutes ?? 0
    let elapsedMinutes = elapsedMinutesSincePlacesFetched
    return max(originalMinutes - elapsedMinutes, 0)
  }

  var elapsedMinutesSincePlacesFetched: Int {
    guard let fetchedAt = store.userSession.explorePlacesFetchedAt else {
      return 0
    }

    return max(Int(Date().timeIntervalSince(fetchedAt) / 60), 0)
  }

  var isVisitUnavailable: Bool {
    remainingStayableMinutes <= 0
  }

  var returnDeadlineSuffixText: String {
    isVisitUnavailable ? "" : " 출발해야 해"
  }

  var openingHoursText: String {
    let weekdayText = summarizedOpeningHours(from: store.placeDetail?.weekday ?? [])
    let weekendText = summarizedOpeningHours(from: store.placeDetail?.weekend ?? [])

    switch (weekdayText.isEmpty, weekendText.isEmpty) {
    case (false, false):
      return "평일 \(weekdayText), 주말 \(weekendText)"
    case (false, true):
      return "평일 \(weekdayText)"
    case (true, false):
      return "주말 \(weekendText)"
    case (true, true):
      return "영업 시간 정보 준비 중"
    }
  }

  func summarizedOpeningHours(from values: [String]) -> String {
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

  var phoneNumberText: String {
    (store.placeDetail?.phoneNumber)?.nilIfEmpty ?? "전화번호 정보 준비 중"
  }

  var addressText: String {
    (store.placeDetail?.address)?.nilIfEmpty ?? "주소 정보 준비 중"
  }

  var mapRegion: MKCoordinateRegion {
    MKCoordinateRegion(
      center: mapCoordinate,
      span: MKCoordinateSpan(latitudeDelta: 0.0035, longitudeDelta: 0.0035)
    )
  }

  var mapCoordinate: CLLocationCoordinate2D {
    if let placeDetail = store.placeDetail {
      return CLLocationCoordinate2D(
        latitude: placeDetail.stationLat,
        longitude: placeDetail.stationLon
      )
    }

    return CLLocationCoordinate2D(
      latitude: store.userSession.travelStationLat ?? 37.5666805,
      longitude: store.userSession.travelStationLng ?? 126.9784147
    )
  }

  func formattedDeadlineTime(from value: String) -> String? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    guard let date = formatter.date(from: value) else {
      return nil
    }

    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "ko_KR")
    outputFormatter.dateFormat = "a h:mm분"
    return outputFormatter.string(from: date)
  }

  @ViewBuilder
  func spotImageCard(for url: URL?, index: Int) -> some View {
    Group {
      if let url {
        KFImage(url)
          .placeholder {
            imagePlaceholder()
          }
          .cancelOnDisappear(true)
          .fade(duration: 0.2)
          .resizable()
          .scaledToFill()
      } else {
        imagePlaceholder()
      }
    }
    .frame(width: 280, height: 180)
    .background(.gray200)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .overlay(alignment: .bottomLeading) {
      if index == 0 {
        LinearGradient(
          colors: [.black.opacity(0.0), .black.opacity(0.18)],
          startPoint: .top,
          endPoint: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
      }
    }
  }

  func imagePlaceholder() -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .fill(.gray200)

      Image(systemName: "photo")
        .font(.system(size: 28, weight: .medium))
        .foregroundStyle(.gray500)
    }
  }
}

private extension ExploreDetailView {
  @ViewBuilder
  func skeletonContent() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      RoundedRectangle(cornerRadius: 4)
        .fill(.gray200)
        .frame(width: 84, height: 14)
        .skeletonShimmer()
        .padding(.top, 12)

      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 20)
          .fill(.gray200)
          .frame(height: 180)
          .frame(maxWidth: .infinity)
          .skeletonShimmer()

        RoundedRectangle(cornerRadius: 20)
          .fill(.gray200)
          .frame(width: 84, height: 180)
          .skeletonShimmer()
      }
      .padding(.top, 24)

      HStack(spacing: 0) {
        skeletonMetricColumn()
        divider
        skeletonMetricColumn()
        divider
        skeletonMetricColumn()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 16)
      .background(.staticWhite)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .stroke(.gray300, lineWidth: 1)
      }
      .padding(.top, 24)

      RoundedRectangle(cornerRadius: 20)
        .fill(.gray200)
        .frame(height: 84)
        .skeletonShimmer()
        .padding(.top, 24)

      VStack(alignment: .leading, spacing: 16) {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 64, height: 14)
          .skeletonShimmer()

        skeletonInfoRow(lineWidth: 180)
        skeletonInfoRow(lineWidth: 120)
        skeletonInfoRow(lineWidth: 200)
      }
      .padding(.top, 24)

      RoundedRectangle(cornerRadius: 20)
        .fill(.gray200)
        .frame(height: 180)
        .skeletonShimmer()
        .padding(.top, 24)

      Capsule()
        .fill(.gray200)
        .frame(height: 56)
        .skeletonShimmer()
        .padding(.top, 24)
    }
  }

  @ViewBuilder
  func skeletonMetricColumn() -> some View {
    VStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 4)
        .fill(.gray200)
        .frame(width: 46, height: 16)
        .skeletonShimmer()

      RoundedRectangle(cornerRadius: 4)
        .fill(.gray200)
        .frame(width: 34, height: 12)
        .skeletonShimmer()
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func skeletonInfoRow(lineWidth: CGFloat) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Circle()
        .fill(.gray200)
        .frame(width: 20, height: 20)
        .skeletonShimmer()

      VStack(alignment: .leading, spacing: 6) {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 56, height: 12)
          .skeletonShimmer()

        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: lineWidth, height: 14)
          .skeletonShimmer()
      }

      Spacer(minLength: 0)
    }
  }
}

private extension View {
  func skeletonShimmer() -> some View {
    modifier(ExploreDetailSkeletonShimmerModifier())
  }
}

private struct ExploreDetailSkeletonShimmerModifier: ViewModifier {
  @State private var isAnimating = false

  func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { geometry in
          LinearGradient(
            colors: [
              .white.opacity(0),
              .white.opacity(0.28),
              .white.opacity(0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .frame(width: geometry.size.width * 0.55)
          .offset(x: isAnimating ? geometry.size.width * 1.25 : -geometry.size.width * 0.8)
        }
        .clipped()
      }
      .mask(content)
      .onAppear {
        guard !isAnimating else { return }
        withAnimation(
          .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: false)
        ) {
          isAnimating = true
        }
      }
  }
}
