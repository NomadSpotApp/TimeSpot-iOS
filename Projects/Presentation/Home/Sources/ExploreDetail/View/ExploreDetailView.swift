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
            .offset(y: -24)
          }

          ScrollView(.vertical) {
            Group {
              if store.isLoading && store.placeDetail == nil {
                ExploreDetailSkeletonView()
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
          }
          .scrollIndicators(.hidden)
        }

        Spacer()

      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
    .refreshable {
      // 캐시된 이미지 다시 확인
    }
    .onChange(of: store.shouldDismiss) { _, shouldDismiss in
      guard shouldDismiss else { return }
      dismiss()
    }
    .onChange(of: store.showLowStayTimeToast) { _, showToast in
      if showToast {
        ToastManager.shared.showWarning("체류시간이 10분 미만입니다")
        store.send(.view(.hideLowStayTimeToast))
      }
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
    .toastOverlay(
      position: .bottom,
      horizontalPadding: 20,
      bottomPadding: 100
    )
  }
}


private extension ExploreDetailView {

  /// 10자 이상인 텍스트에 중간 스페이스 추가
  private func formatLongText(_ text: String) -> String {
    guard text.count > 10 else { return text }

    let characters = Array(text)
    let midPoint = characters.count / 2

    // 중간점 근처에서 적절한 위치 찾기 (±2 범위 내)
    let searchRange = max(0, midPoint - 2)...min(characters.count - 1, midPoint + 2)

    // 이미 스페이스가 있는 위치 찾기
    if let spaceIndex = searchRange.first(where: { characters[$0] == " " }) {
      return text
    }

    // 스페이스가 없으면 중간에 스페이스 추가
    let insertIndex = midPoint
    var result = characters
    result.insert(" ", at: insertIndex)

    return String(result)
  }

  @ViewBuilder
  func exploreSpotNameTitle() -> some View {
    VStack(alignment: .leading) {
      HStack(spacing: 8) {
        Text(formatLongText(store.placeNameText.formattedPlaceNameForDisplay))
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.staticBlack)
          .lineLimit(2)

        Text(formatLongText(store.categoryText))
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
        ForEach(store.imageCards.indices, id: \.self) { index in
          spotImageCard(for: store.imageCards[index], index: index)
        }
      }
    }
  }

  @ViewBuilder
  func stayInfoSection() -> some View {
    HStack(spacing: 0) {
      metricColumn(
        value: formatLongText(store.stayableMinutesText),
        title: "체류시간",
        valueColor: .orange800
      )

      divider

      metricColumn(
        value: formatLongText(store.walkMinutesText),
        title: "도보",
        valueColor: .gray830
      )

      divider

      metricColumn(
        value: formatLongText(store.distanceText),
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
              .foregroundStyle(.staticBlack)

            Spacer()
          }

          (
            Text(formatLongText(store.returnDeadlineText))
              .foregroundStyle(store.isVisitUnavailable ? .gray700 : .orange800)
            +
            Text(formatLongText(store.returnDeadlineSuffixText)).foregroundStyle(.gray800)
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
          content: formatLongText(store.openingHoursText)
        )

        infoRow(
          icon: "phone.fill",
          title: "전화번호",
          content: formatLongText(store.phoneNumberText)
        )

        infoRow(
          icon: "location.fill",
          title: "주소",
          content: formatLongText(store.addressText)
        )
      }
    }
  }

  @ViewBuilder
  func locationMapSection() -> some View {
    GeometryReader { proxy in
      Map(initialPosition: .region(store.mapRegion), interactionModes: .all) {
        Annotation(formatLongText(store.placeNameText), coordinate: store.mapCoordinate) {
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
      title: store.isVisitUnavailable ? "방문 불가" : "경로 확인하기",
      config: CustomButtonConfig.create(),
      isEnable: !store.isVisitUnavailable
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

  // All computed properties moved to ExploreDetailFeature.State extension

  // Helper function moved to ExploreDetailFeature.State extension

  @ViewBuilder
  func spotImageCard(for url: URL?, index: Int) -> some View {
    Group {
      if let url {
        // Google Places API 이미지 로드 (제한적 네트워크 허용)
        KFImage(url)
          .placeholder {
            imagePlaceholder()
          }
          .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 280, height: 180)))
          .loadDiskFileSynchronously()
          .memoryCacheExpiration(.seconds(1800))
          .diskCacheExpiration(.days(7)) // 더 긴 캐시 (할당량 절약)
          .requestModifier(rateLimitedImageModifier)
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

  // Rate Limiting을 고려한 Google Places API 이미지용 요청 modifier
  private var rateLimitedImageModifier: AnyModifier {
    AnyModifier { request in
      var modifiedRequest = request
      modifiedRequest.timeoutInterval = 45.0 // 더 긴 타임아웃
      modifiedRequest.setValue("TimeSpot-iOS/1.0", forHTTPHeaderField: "User-Agent")
      modifiedRequest.setValue("image/*", forHTTPHeaderField: "Accept")
      // Rate limiting 방지를 위해 캐시 우선 사용
      modifiedRequest.cachePolicy = .returnCacheDataElseLoad

      return modifiedRequest
    }
  }

  // 캐시된 이미지만 클리어 (네트워크 요청 없음)
  private func forceReloadImages() {
    let urls = store.imageCards.compactMap { $0 }
    for url in urls {
      KingfisherManager.shared.cache.removeImage(forKey: url.absoluteString)
    }
  }

  // Rate Limit을 고려한 제한적 프리페칭 (첫 번째 이미지만)
  private func prefetchImagesWithRateLimit() {
    let urls = store.imageCards.compactMap { $0 }
    guard !urls.isEmpty else { return }

    // 첫 번째 이미지만 프리페치 (Rate Limit 방지)
    let limitedUrls = Array(urls.prefix(1))

    let prefetcher = ImagePrefetcher(
      urls: limitedUrls,
      options: [
        .processor(DownsamplingImageProcessor(size: CGSize(width: 280, height: 180))),
        .requestModifier(rateLimitedImageModifier),
        .backgroundDecode,
        .diskCacheExpiration(.days(1)),
        .memoryCacheExpiration(.seconds(1800))
      ]
    )

    prefetcher.start()
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

  func loadingPlaceholder() -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .fill(.gray200)

      VStack(spacing: 8) {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .gray600))
          .scaleEffect(0.8)

        Text("로딩 중...")
          .pretendardCustomFont(textStyle: .body2Regular)
          .foregroundStyle(.gray600)
      }
    }
  }

}
