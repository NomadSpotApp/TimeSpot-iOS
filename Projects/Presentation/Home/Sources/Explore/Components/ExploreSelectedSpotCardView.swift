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

  private func cardContent(for spot: ExploreMapSpot) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 0) {
          // 뱃지는 visitable 상태와 무관하게 항상 표시
          if !spot.badgeText.isEmpty {
            Text(formatLongText(spot.badgeText))
              .pretendardCustomFont(textStyle: .caption)
              .foregroundStyle(.orange800)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(.orange200)
              .clipShape(Capsule())
              .padding(.bottom, 12)
          }

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
              Text(formatLongText(spot.subtitle))
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

          if !spot.statusText.isEmpty || !spot.closingText.isEmpty {
            HStack(spacing: 12) {
              if !spot.statusText.isEmpty {
                Text(formatLongText(spot.statusText))
                  .pretendardCustomFont(textStyle: .body2Medium)
                  .foregroundStyle(.gray850)
              }

              if !spot.closingText.isEmpty {
                Text(formatLongText(spot.closingText))
                  .pretendardCustomFont(textStyle: .body2Regular)
                  .foregroundStyle(.gray750)
                  .lineLimit(1)
              }
            }
            .padding(.bottom, 10)
          }

          if !spot.distanceText.isEmpty || !spot.walkTimeText.isEmpty {
            HStack(spacing: 8) {
              if !spot.distanceText.isEmpty {
                Text(formatLongText(spot.distanceText))
                  .pretendardCustomFont(textStyle: .bodyBold)
                  .foregroundStyle(.gray830)
              }

              if !spot.walkTimeText.isEmpty {
                Text(formatLongText(spot.walkTimeText))
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
      .onTapGesture(perform: onCardTap)
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 20)

      Button(action: spot.visitable ? onRouteTap : {}) {
        Text(spot.visitable ? "경로 확인하기" : "방문 불가")
          .pretendardCustomFont(textStyle: .bodyBold)
          .foregroundStyle(.staticWhite)
          .frame(maxWidth: .infinity)
          .frame(height: 55)
          .background(spot.visitable ? .navy900 : .gray500)
          .clipShape(RoundedRectangle(cornerRadius: 25))
      }
      .buttonStyle(.plain)
      .disabled(!spot.visitable)
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
          .memoryCacheExpiration(.seconds(300))
          .loadDiskFileSynchronously()
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

  private func formattedDisplayName(for spot: ExploreMapSpot) -> String {
    return formatLongText(spot.name.formattedPlaceNameForDisplay)
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
