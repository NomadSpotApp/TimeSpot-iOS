//
//  ExploreSelectedSpotCardView.swift
//  Home
//

import SwiftUI

import DesignSystem
import Entity
import Kingfisher
import Utill
import ComposableArchitecture
import LogMacro

struct ExploreSelectedSpotCardView: View {
  let currentSpot: ExploreMapSpot
  let adjacentSpot: ExploreMapSpot?
  let store: StoreOf<ExploreFeature>
  let currentOffset: CGFloat
  let adjacentOffset: CGFloat?
  let cardOpacity: Double
  let onCardTap: () -> Void
  let onRouteTap: () -> Void
  let onDragChanged: (DragGesture.Value) -> Void
  let onDragEnded: (DragGesture.Value) -> Void

  var body: some View {
    ZStack {
      if let adjacentSpot, let adjacentOffset {
        cardContent(for: adjacentSpot)
          .offset(x: adjacentOffset)
          .allowsHitTesting(false)
      }

      cardContent(for: currentSpot)
        .offset(x: currentOffset)
        .opacity(cardOpacity)
    }
    .gesture(
      DragGesture(minimumDistance: 20)
        .onChanged(onDragChanged)
        .onEnded(onDragEnded)
    )
  }

  /// 체류 가능 시간 계산
  private func calculateStayableMinutes(for spot: ExploreMapSpot) -> Int {
    // 도보 시간이 있으면 해당 시간 사용, 없으면 거리 기반 추정
    let walkTime: Int
    if let walkTimeText = spot.walkTimeText.components(separatedBy: "약 ").last?.components(separatedBy: "분").first,
       let time = Int(walkTimeText) {
      walkTime = time
    } else {
      // 거리 기반 추정 도보시간 (1분/67m)
      let distance = Int(spot.distanceText.components(separatedBy: "m").first ?? "0") ?? 0
      walkTime = max(Int(ceil(Double(distance) / 67.0)), 1)
    }

    // 왕복 도보 시간 = 편도 도보 시간 × 2
    let roundTripWalkTime = walkTime * 2

    // 플랫폼 대기 시간 = 10분 (고정)
    let platformWaitTime = 10

    // 체류 가능 시간 = 남은 시간 - 왕복 도보 시간 - 플랫폼 대기 시간
    let stayableTime = spot.stayableMinutes - roundTripWalkTime - platformWaitTime

    // 음수 방지
    return max(0, stayableTime)
  }

  /// 접근 가능 여부 판단 (두 가지 조건)
  private func isSpotAccessible(_ spot: ExploreMapSpot) -> Bool {
    // 조건 1: 기본 방문 가능 여부
    guard spot.visitable else { return false }

    // 조건 2: 체류시간 계산 결과 5분 이상
    return calculateStayableMinutes(for: spot) >= 5
  }

  /// 버튼 텍스트
  private func buttonTitle(for spot: ExploreMapSpot) -> String {
    if !spot.visitable {
      return "방문 불가"
    } else {
      let calculatedStayableMinutes = calculateStayableMinutes(for: spot)
      if calculatedStayableMinutes == 0 {
        return "체류시간 부족"
      } else if calculatedStayableMinutes < 5 {
        return "체류시간 부족"
      } else {
        return "경로 확인하기"
      }
    }
  }

  /// 버튼 배경색
  private func buttonBackgroundColor(for spot: ExploreMapSpot) -> Color {
    isSpotAccessible(spot) ? .navy900 : .gray500
  }

  /// 포맷된 거리 텍스트 (1000m 이상은 km로 표시)
  private func formattedDistanceText(for spot: ExploreMapSpot) -> String {
    let distance = Int(spot.distanceText.components(separatedBy: "m").first ?? "0") ?? 0
    return distance.formattedDistance
  }

  private func cardContent(for spot: ExploreMapSpot) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 0) {
          // 체류 가능 시간 표시 (항상 stayableMinutes 표시)
          Text("\(spot.stayableMinutes)분 체류 가능")
            .pretendardCustomFont(textStyle: .caption)
            .foregroundStyle(.orange800)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.orange200)
            .clipShape(Capsule())
            .padding(.bottom, 12)

          HStack(alignment: .top, spacing: 6) {
            Text(formattedDisplayName(for: spot))
              .pretendardFont(family: .SemiBold, size: 18)
              .foregroundStyle(.staticBlack)
              .lineLimit(titleLineLimit(for: spot))
              .minimumScaleFactor(0.7)
              .truncationMode(.tail)
              .fixedSize(horizontal: false, vertical: true)
              .layoutPriority(1)

            if !spot.subtitle.isEmpty {
              Text(spot.subtitle.formatLongText)
                .pretendardCustomFont(textStyle: .caption)
                .foregroundStyle(.gray650)
                .lineLimit(1)
                .fixedSize()
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
          }
          .frame(minHeight: titleMinHeight(for: spot), alignment: .topLeading)
          .padding(.bottom, 4)

          if !spot.closingText.isEmpty {
            HStack(spacing: 12) {
              Text(spot.closingText.formatLongText)
                .pretendardCustomFont(textStyle: .body2Regular)
                .foregroundStyle(.gray750)
                .lineLimit(1)
            }
            .padding(.bottom, 10)
          }

          if !spot.distanceText.isEmpty || !spot.walkTimeText.isEmpty {
            HStack(spacing: 8) {
              if !spot.distanceText.isEmpty {
                Text(formattedDistanceText(for: spot).formatLongText)
                  .pretendardCustomFont(textStyle: .bodyBold)
                  .foregroundStyle(.gray830)
              }

              if !spot.walkTimeText.isEmpty {
                Text(spot.walkTimeText.formatLongText)
                  .pretendardCustomFont(textStyle: .bodyRegular)
                  .foregroundStyle(.gray830)
                  .lineLimit(1)
              }
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        spotImage(for: spot)
      }
      .contentShape(Rectangle())
      .onTapGesture {
        if isSpotAccessible(spot) {
          onCardTap()
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 20)

      Button(action: isSpotAccessible(spot) ? onRouteTap : {}) {
        Text(buttonTitle(for: spot))
          .pretendardCustomFont(textStyle: .bodyBold)
          .foregroundStyle(.staticWhite)
          .frame(maxWidth: .infinity)
          .frame(height: 55)
          .background(buttonBackgroundColor(for: spot))
          .clipShape(RoundedRectangle(cornerRadius: 25))
      }
      .buttonStyle(.plain)
      .disabled(!isSpotAccessible(spot))
      .padding(.horizontal, 16)
      .padding(.bottom, 12)
    }
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
    .transaction { transaction in
      transaction.animation = nil
    }
  }

  @ViewBuilder
  private func spotImage(for spot: ExploreMapSpot) -> some View {
    Group {
      if let url = imageURL(for: spot) {
        KFImage(url)
          .placeholder {
            imagePlaceholder()
          }
          .cacheMemoryOnly(false)
          .diskCacheExpiration(.days(7))
          .memoryCacheExpiration(.seconds(1800))
          .cancelOnDisappear(true)
          .fade(duration: 0.2)
          .resizable()
          .scaledToFill()
          .frame(width: 92, height: 112)
          .clipShape(RoundedRectangle(cornerRadius: 16))
      } else {
        imagePlaceholder()
      }
    }
  }

  private func titleLineLimit(for spot: ExploreMapSpot) -> Int {
    return 1 // 항상 한 줄로 표시
  }

  private func titleMinHeight(for spot: ExploreMapSpot) -> CGFloat {
    return 24 // 고정 높이
  }

  private func formattedDisplayName(for spot: ExploreMapSpot) -> String {
    return spot.name.formattedPlaceNameForDisplay.formatLongText
  }

  private func imageURL(for spot: ExploreMapSpot) -> URL? {
    // 1. 기존 spot.imageURL이 있으면 우선 사용
    if let imageURL = spot.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
       !imageURL.isEmpty {
      if let url = URL(string: imageURL) {
        return url
      }
      let encoded = imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      return encoded.flatMap(URL.init(string:))
    }


    return nil
  }

  private func imagePlaceholder() -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(.gray200)

      Image(systemName: "photo")
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(.gray500)
    }
    .frame(width: 92, height: 112)
  }

}
