//
//  ExploreSpotListCardView.swift
//  Home
//

import SwiftUI

import DesignSystem
import Entity
import Kingfisher
import Utill
import ComposableArchitecture
import LogMacro

struct ExploreSpotListCardView: View {
  let spot: ExploreMapSpot
  let store: StoreOf<ExploreListFeature>

  var body: some View {
    Button {
      store.send(.view(.spotCardTapped(spot)))
    } label: {
      HStack(alignment: .top, spacing: 14) {
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

        VStack(alignment: .leading, spacing: 6) {
          titleRow
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: titleMinHeight, alignment: .topLeading)
        }
        .padding(.bottom, 8)

        HStack(spacing: 10) {
          if !spot.statusText.isEmpty {
            Text(spot.statusText.formatLongText)
              .pretendardCustomFont(textStyle: .body2Medium)
              .foregroundStyle(.gray700)
              .fixedSize()
          }

          if !spot.closingText.isEmpty {
            Text(spot.closingText.formatLongText)
              .pretendardCustomFont(textStyle: .body2Regular)
              .foregroundStyle(.gray750)
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, alignment: .leading)
              .truncationMode(.tail)
          }
        }
        .padding(.bottom, 10)

        HStack(spacing: 8) {
          if !spot.distanceText.isEmpty {
            Text(formattedDistanceText.formatLongText)
              .pretendardFont(family: .SemiBold, size: 16)
              .foregroundStyle(.staticBlack)
              .fixedSize()
          }

          if !spot.walkTimeText.isEmpty {
            Text(spot.walkTimeText.formatLongText)
              .pretendardCustomFont(textStyle: .body2Regular)
              .foregroundStyle(.gray830)
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, alignment: .leading)
              .truncationMode(.tail)
          }
        }

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      spotImage(for: spot)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 16)
      .background(.staticWhite)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .overlay {
        RoundedRectangle(cornerRadius: 22)
          .stroke(.enableColor, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var titleRow: some View {
    HStack(alignment: .top, spacing: 6) {
      Text(formattedDisplayName)
        .font(.pretendardFontFamily(family: .SemiBold, size: 18))
        .foregroundStyle(.staticBlack)
        .lineLimit(titleLineLimit)
        .minimumScaleFactor(0.7)
        .layoutPriority(1)

      if !spot.subtitle.isEmpty {
        Text(spot.subtitle.formatLongText)
          .font(.pretendardFontFamily(family: .Medium, size: 14))
          .foregroundStyle(.gray700)
          .lineLimit(1)
          .fixedSize()
          .padding(.top, 2)
      }

      Spacer(minLength: 0)
    }
  }

  private var titleLineLimit: Int {
    return 1 // 항상 한 줄로 표시
  }

  private var titleMinHeight: CGFloat {
    return 24 // 고정 높이
  }

  private var formattedDisplayName: String {
    return spot.name.formattedPlaceNameForDisplay.formatLongText
  }

  @ViewBuilder
  private func spotImage(for spot: ExploreMapSpot) -> some View {
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
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(.gray500)
    }
    .frame(width: 92, height: 112)
  }

  /// 포맷된 거리 텍스트 (1000m 이상은 km로 표시)
  private var formattedDistanceText: String {
    let distance = Int(spot.distanceText.components(separatedBy: "m").first ?? "0") ?? 0
    return distance.formattedDistance
  }
}
