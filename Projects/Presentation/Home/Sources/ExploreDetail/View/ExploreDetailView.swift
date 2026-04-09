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

        VStack(spacing: 0) {
          // 상단 네비게이션 바
          if !store.isLoading {
            ExploreDetailNavigationBar(
              placeName: store.placeNameText.formattedPlaceNameForDisplay,
              category: store.categoryText,
              showTitle: store.showNavigationTitle,
              onBackTap: {
                dismiss()
              }
            )
            .padding(.horizontal, 16)
            .padding(.top, store.placeDetail == nil ? 8 : -30)
          }

          // 스크롤 가능한 컨텐츠
          ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
              LazyVStack(alignment: .leading, spacing: 0) {
                Group {
                  if store.isLoading {
                    ExploreDetailSkeletonView()
                  } else if (store.placeDetail == nil && store.errorMessage != nil) || store.isVisitUnavailable {
                    // 404 에러 또는 방문 불가인 경우
                    noDetailContentView()
                  } else {
                    VStack(alignment: .leading, spacing: 0) {
                      exploreSpotNameTitle()
                        .padding(.top, 18) // 6 + 18 = 24 (네비게이션에서 총 24만큼 떨어짐)
                        .id("title")

                      imageSection()
                        .padding(.top, 24)
                        .id("images")
                        .background(
                          GeometryReader { imageGeo in
                            Color.clear
                              .onAppear {
                                // 이미지 섹션 위치 감지
                                let imageFrame = imageGeo.frame(in: .global)
                                store.send(.view(.titlePositionChanged(imageFrame.minY)))
                              }
                              .onChange(of: imageGeo.frame(in: .global).minY) { _, newY in
                                store.send(.view(.titlePositionChanged(newY)))
                              }
                          }
                        )

                      stayInfoSection()
                        .padding(.top, 24)

                      returnDeadlineSection()
                        .padding(.top, 24)

                      placeInfoSection()
                        .padding(.top, 29)

                      locationMapSection()
                        .padding(.top, 24)
                        .id("map")

                      // 고정 버튼 영역만큼 하단 공간 확보
                      Color.clear
                        .frame(height: 131) // 간격 41 + 버튼 높이 56 + 하단 패딩 34
                        .id("bottom")

                    }
                  }
                }
                .padding(.horizontal, 16)
              }
            }
            .scrollIndicators(.hidden)
            .padding(.top, store.placeDetail != nil ? 6 : 20) // placeDetail 있으면 6, 없으면 20
          }
          .offset(y: -10)
        }

        // 하단 고정 버튼
        VStack {
          Spacer()

          if !store.isLoading {
            VStack(spacing: 0) {
              // 투명한 상단 간격 (콘텐츠가 보이도록)
              Spacer()
                .frame(height: 41)

              // 버튼 영역만 배경 적용
              if store.placeDetail == nil && store.errorMessage != nil {
                // 404 에러인 경우 지도보기 버튼
                HStack {
                  Spacer()
                  mapButtonSection()
                  Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .background(.gray100)
              } else if !store.isVisitUnavailable {
                // 방문 가능한 경우 경로 확인하기 버튼
                routeButtonSection()
                  .padding(.horizontal, 16)
                  .padding(.bottom, 24)
                  .background(.gray100)
              }
            }
          }
        }
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
    .onChange(of: store.shouldDismiss) { _, shouldDismiss in
      guard shouldDismiss else { return }
      dismiss()
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
    .toastOverlay(
      position: .top,
      horizontalPadding: 20,
      topPadding: 80 // 상단 네비게이션 바 아래에 토스트 표시
    )
  }
}


private extension ExploreDetailView {


  @ViewBuilder
  func exploreSpotNameTitle() -> some View {
    HStack(spacing: 8) {
      Text(store.placeNameText.formattedPlaceNameForDisplay.formatLongText)
        .pretendardCustomFont(textStyle: .heading1)
        .foregroundStyle(.staticBlack)
        .lineLimit(2)

      Text(store.categoryText.formatLongText)
        .pretendardCustomFont(textStyle: .body2Regular)
        .foregroundStyle(.gray700)

      Spacer()
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
        value: store.stayableMinutesText.formatLongText,
        title: "체류시간",
        valueColor: .orange800
      )

      divider

      metricColumn(
        value: store.walkMinutesText.formatLongText,
        title: "도보",
        valueColor: .gray830
      )

      divider

      metricColumn(
        value: store.distanceText.formatLongText,
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
            Text(store.returnDeadlineText.formatLongText)
              .foregroundStyle(store.isVisitUnavailable ? .gray700 : .orange800)
            +
            Text(store.returnDeadlineSuffixText.formatLongText).foregroundStyle(.gray800)
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
          content: store.openingHoursText.formatLongText
        )

        infoRow(
          icon: "phone.fill",
          title: "전화번호",
          content: store.phoneNumberText.formatLongText
        )

        infoRow(
          icon: "location.fill",
          title: "주소",
          content: store.addressText.formatLongText
        )
      }
    }
  }

  @ViewBuilder
  func locationMapSection() -> some View {
    GeometryReader { proxy in
      if let placeDetail = store.placeDetail {
        // placeDetail이 로딩된 후 유효한 좌표로만 지도 표시
        let coordinate = CLLocationCoordinate2D(
          latitude: placeDetail.latitude,
          longitude: placeDetail.longitude
        )

        if coordinate.latitude != 0 && coordinate.longitude != 0 {
          Map(initialPosition: .region(store.mapRegion), interactionModes: []) {
            Annotation(store.placeNameText.formatLongText, coordinate: coordinate) {
              Image(asset: .spotPin)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 28)
            }
          }
          .mapStyle(.standard)
          .frame(width: proxy.size.width, height: 180)
          .clipShape(RoundedRectangle(cornerRadius: 20))
          .clipped()
        } else {
          // 좌표가 유효하지 않을 때
          RoundedRectangle(cornerRadius: 20)
            .fill(.gray200)
            .frame(width: proxy.size.width, height: 180)
            .overlay {
              VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                  .font(.system(size: 24, weight: .medium))
                  .foregroundStyle(.orange600)

                Text("위치 정보를 찾을 수 없습니다")
                  .pretendardCustomFont(textStyle: .body2Regular)
                  .foregroundStyle(.gray600)
              }
            }
        }
      } else {
        // placeDetail 로딩 중에는 플레이스홀더 표시
        RoundedRectangle(cornerRadius: 20)
          .fill(.gray200)
          .frame(width: proxy.size.width, height: 180)
          .overlay {
            VStack(spacing: 8) {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .gray600))
                .scaleEffect(0.8)

              Text("지도 로딩 중...")
                .pretendardCustomFont(textStyle: .body2Regular)
                .foregroundStyle(.gray600)
            }
          }
      }
    }
    .frame(height: 180)
  }

  @ViewBuilder
  func routeButtonSection() -> some View {
    CustomButton(
      action: {
        store.send(.view(.routeButtonTapped))
      },
      title: store.isVisitUnavailable ? "방문 불가" : "경로 확인하기",
      config: CustomButtonConfig.create(),
      isEnable: !store.isVisitUnavailable
    )
  }

  @ViewBuilder
  func mapButtonSection() -> some View {
    Button {
      store.send(.delegate(.presentExploreMapAtCurrentLocation))
    } label: {
      HStack(alignment: .center, spacing: 4) {
        Image(asset: .locationBadge)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)

        Text("지도보기")
          .pretendardCustomFont(textStyle: .body2Bold)
          .foregroundStyle(.staticWhite)
      }
      .padding(.horizontal, 15)
      .padding(.vertical, 10)
      .background(.orange800)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
      .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 8)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func buttonsSection() -> some View {
    HStack(spacing: 12) {
      // 지도보기 버튼
      Button {
        store.send(.delegate(.presentExploreMapAtCurrentLocation))
      } label: {
        HStack(alignment: .center, spacing: 4) {
          Image(asset: .locationBadge)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)

          Text("지도보기")
            .pretendardCustomFont(textStyle: .body2Bold)
            .foregroundStyle(.staticWhite)
        }
        .frame(height: 55)
        .padding(.horizontal, 15)
        .background(.orange800)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 8)
      }
      .buttonStyle(.plain)

      // 경로 확인하기 버튼
      CustomButton(
        action: {
          store.send(.view(.routeButtonTapped))
        },
        title: "경로 확인하기",
        config: CustomButtonConfig.create(),
        isEnable: true
      )
    }
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


  @ViewBuilder
  func noDetailContentView() -> some View {
    GeometryReader { geometry in
      VStack(spacing: 24) {
        Spacer()

        Image(asset: .noDetailSpot)
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)

        Text("시간 부족으로\n장소 방문이 불가해요")
          .pretendardCustomFont(textStyle: .bodyMedium)
          .foregroundStyle(.gray550)
          .multilineTextAlignment(.center)

        Spacer()
      }
      .frame(width: geometry.size.width, height: max(geometry.size.height, UIScreen.main.bounds.height - 200))
    }
  }
}

