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
          CustomNavigationBackBar(buttonAction: {
            dismiss()
          }, title: "")
          .padding(.horizontal, 16)
          .offset(y: -30)

          ScrollView(.vertical) {
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
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
          }
          .scrollIndicators(.hidden)
        }

      }
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
        Text(store.spot.name.formattedPlaceNameForDisplay)
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.staticBlack)
          .lineLimit(2)

        Text(store.spot.subtitle)
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
        value: store.spot.distanceText,
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
            Text(returnDeadlineText).foregroundStyle(.orange800)
            +
            Text("에는 역으로 출발해야 합니다.").foregroundStyle(.gray800)
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
        Annotation(store.spot.name, coordinate: store.spot.coordinate) {
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
      title: "경로 확인하기",
      config: CustomButtonConfig.create(),
      isEnable: true
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
    store.spot.badgeText.stayableMinutesDisplayText
  }

  var walkMinutesText: String {
    store.spot.walkTimeText.walkMinutesDisplayText(
      spotName: store.spot.name,
      subtitle: store.spot.subtitle,
      distanceText: store.spot.distanceText
    )
  }

  var imageCards: [URL?] {
    if let imageURL {
      return [imageURL, imageURL]
    }
    return [nil, nil]
  }

  var imageURL: URL? {
    store.spot.imageURL?.normalizedURL
  }

  var returnDeadlineText: String {
    Date().formattedReturnDeadlineText(addingMinutes: stayableMinutesValue)
  }

  var stayableMinutesValue: Int {
    stayableMinutesText.minutesValue
  }

  var openingHoursText: String {
    String.openingHoursText(
      status: store.spot.statusText,
      closing: store.spot.closingText
    )
  }

  var phoneNumberText: String {
    "전화번호 정보 준비 중"
  }

  var addressText: String {
    store.spot.coordinate.approximateAddressText
  }

  var mapRegion: MKCoordinateRegion {
    MKCoordinateRegion(
      center: store.spot.coordinate,
      span: MKCoordinateSpan(latitudeDelta: 0.0035, longitudeDelta: 0.0035)
    )
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
