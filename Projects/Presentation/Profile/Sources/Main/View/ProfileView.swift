//
//  ProfileView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import SwiftUI

import DesignSystem
import Entity

import ComposableArchitecture

public struct ProfileView: View {
  @Bindable var store: StoreOf<ProfileFeature>

  public init(store: StoreOf<ProfileFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.gray100
        .edgesIgnoringSafeArea(.all)

      if store.isLoading || store.profileEntity == nil {
        profileSkeletonView()
      } else {
        VStack {
          Spacer()
            .frame(height: 8)

          CustomNavigationBar(
            title: "마이페이지",
            leftImage: .leftArrow,
            rightImage: .setting,
            leftAction: {
              store.send(.delegate(.presentBack))
            },
            rightAction: {
              store.send(.delegate(.presentSetting))
            }
          )
          
          profileInfoCardView()

          travelHistory()

          Spacer()

        }
        .padding(.horizontal, 16)
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}

extension ProfileView {
  private var travelHistoryItems: [HistoryItemEntity] {
    store.historyEntity?.items ?? []
  }

  @ViewBuilder
  private func profileInfoCardView() -> some View {
    VStack(alignment: .leading) {
      VStack {
        Spacer()
          .frame(height: 16)
        
        HStack {
          Text("\(store.profileEntity?.nickname ?? "사용자")님")
            .pretendardCustomFont(textStyle: .heading1)
            .foregroundStyle(.staticWhite)

          Spacer()
        }
        .padding(.horizontal, 8)

        Spacer()
          .frame(height: 3)

        HStack {
          switch store.profileEntity?.provider {
            case .apple:
              Image(systemName: store.profileEntity?.provider.image ?? "")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.blueGray300)

            case .google:
              Image(assetName: store.profileEntity?.provider.image ?? "")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
              
            case nil:
              Image(systemName: store.profileEntity?.provider.image ?? "")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.blueGray300)
          }



          Spacer()
            .frame(width: 4)

          Text(verbatim: store.profileEntity?.email ?? "user@example.com")
            .pretendardCustomFont(textStyle: .body2Medium)
            .foregroundStyle(.blueGray300)

          Spacer()

        }
        .padding(.horizontal, 8)


        Spacer()
          .frame(height: 24)

        HStack {
          Spacer()

          VStack(alignment: .center) {
            Text("방문한 장소")
              .pretendardCustomFont(textStyle: .caption)
              .foregroundStyle(.staticWhite)

            Spacer()
              .frame(height: 4)

            Text("\(store.profileEntity?.totalVisitCount ?? 0)곳")
              .pretendardFont(family: .SemiBold, size: 16)
              .foregroundStyle(.staticWhite)


          }

          Spacer()

          Image(asset: .lineHeight)
            .resizable()
            .scaledToFit()
            .frame(height: 48)

          Spacer()

          VStack(alignment: .center) {
            Text("탐험 시간")
              .pretendardCustomFont(textStyle: .caption)
              .foregroundStyle(.staticWhite)

            Spacer()
              .frame(height: 4)

            Text(store.profileEntity?.formattedJourneyTime ?? "0시간00분")
              .pretendardFont(family: .SemiBold, size: 16)
              .foregroundStyle(.staticWhite)


          }

          Spacer()

        }
        .padding(.horizontal, 21)
        .padding(.vertical, 11)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.blueGray800)
        )
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.navy900)
      )
    }
  }

  @ViewBuilder
  fileprivate func travelHistory() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
        .frame(height: 40)

      HStack {
        Text("나의 히스토리")
          .pretendardCustomFont(textStyle: .titleRegular)
          .foregroundStyle(.staticBlack)

        Spacer()

        Menu {
          ForEach(TravelHistorySort.allCases, id: \.self) { sort in
            Button {
              store.send(.view(.travelHistorySortSelected(sort)))
            } label: {
              HStack {
                Text(sort.title)
                  .pretendardCustomFont(textStyle: .bodyMedium)
                  .foregroundStyle(.gray800)

                Spacer()

                if store.travelHistorySort == sort {
                  Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.gray800)
                }
              }
              .environment(\.layoutDirection, .leftToRight)
            }
          }
        } label: {
          HStack(spacing: 8) {
            Text(store.travelHistorySort.title)
              .pretendardCustomFont(textStyle: .bodyMedium)
              .foregroundStyle(.staticBlack)
              .fixedSize(horizontal: true, vertical: false)

            Image(asset: .arrowtriangleDown)
              .resizable()
              .scaledToFit()
              .frame(width: 12, height: 12)
          }
          .frame(minWidth: 128, alignment: .trailing)
        }
      }

      Spacer()
        .frame(height: 20)

      if travelHistoryItems.isEmpty, !store.isHistoryLoading, !store.isHistoryLoadingMore {
        VStack(spacing: 0) {
          Spacer()

          Image(asset: .empyTravel)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)

          Spacer()
            .frame(height: 24)

          Text("저장된 히스토리가 없습니다.")
            .pretendardCustomFont(textStyle: .bodyRegular)
            .foregroundStyle(.gray550)

          Spacer()
        }
        .frame(maxWidth: .infinity)
      } else {
        ScrollView(.vertical) {
          LazyVStack(spacing: 12) {
            ForEach(travelHistoryItems) { item in
              TravelHistoryCardView(item: item.toCardItem())
                .onAppear {
                  store.send(.view(.historyRowAppeared(item.id)))
                }
            }

            if store.isHistoryLoadingMore {
              ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
          }
        }
        .scrollIndicators(.hidden)
      }
    }
  }

  @ViewBuilder
  private func profileSkeletonView() -> some View {
    VStack {
      Spacer()
        .frame(height: 8)

      CustomNavigationBar(
        title: "마이페이지",
        leftImage: .leftArrow,
        rightImage: .setting,
        leftAction: {
          store.send(.delegate(.presentBack))
        },
        rightAction: {}
      )

      profileInfoCardSkeletonView()

      travelHistorySkeletonView()

      Spacer()
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  private func profileInfoCardSkeletonView() -> some View {
    VStack(alignment: .leading) {
      VStack {
        Spacer()
          .frame(height: 12)

        HStack {
          RoundedRectangle(cornerRadius: 6)
            .fill(.blueGray800)
            .frame(width: 100, height: 24)
            .opacity(0.7)

          Spacer()
        }
        .padding(.horizontal, 8)

        Spacer()
          .frame(height: 3)

        HStack {
          Circle()
            .fill(.blueGray800)
            .frame(width: 16, height: 16)
            .opacity(0.7)

          Spacer()
            .frame(width: 4)

          RoundedRectangle(cornerRadius: 4)
            .fill(.blueGray800)
            .frame(width: 150, height: 14)
            .opacity(0.7)

          Spacer()
        }
        .padding(.horizontal, 8)

        Spacer()
          .frame(height: 24)

        HStack {
          Spacer()

          VStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray800)
              .frame(width: 60, height: 12)
              .opacity(0.7)

            Spacer()
              .frame(height: 4)

            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray800)
              .frame(width: 40, height: 16)
              .opacity(0.7)
          }

          Spacer()

          Image(asset: .lineHeight)
            .resizable()
            .scaledToFit()
            .frame(height: 48)

          Spacer()

          VStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray800)
              .frame(width: 50, height: 12)
              .opacity(0.7)

            Spacer()
              .frame(height: 4)

            RoundedRectangle(cornerRadius: 4)
              .fill(.blueGray800)
              .frame(width: 70, height: 16)
              .opacity(0.7)
          }

          Spacer()
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 11)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.blueGray800)
        )
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.navy900)
      )
    }
  }

  @ViewBuilder
  private func travelHistorySkeletonView() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
        .frame(height: 40)

      HStack {
        RoundedRectangle(cornerRadius: 6)
          .fill(.gray300)
          .frame(width: 120, height: 20)
          .opacity(0.7)

        Spacer()

        RoundedRectangle(cornerRadius: 4)
          .fill(.gray300)
          .frame(width: 80, height: 16)
          .opacity(0.7)
      }

      Spacer()
        .frame(height: 20)

      ScrollView(.vertical) {
        VStack(spacing: 12) {
          ForEach(0..<3, id: \.self) { _ in
            travelHistoryCardSkeletonView()
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  @ViewBuilder
  private func travelHistoryCardSkeletonView() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      RoundedRectangle(cornerRadius: 4)
        .fill(.gray300)
        .frame(width: 80, height: 12)
        .opacity(0.7)

      Spacer()
        .frame(height: 10)

      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 120, height: 20)
            .opacity(0.7)

          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 60, height: 14)
            .opacity(0.7)
        }

        Spacer()

        RoundedRectangle(cornerRadius: 3)
          .fill(.gray300)
          .frame(width: 123, height: 6)
          .padding(.vertical, 9)
          .opacity(0.7)

        Spacer()
          .frame(width: 24)

        VStack(alignment: .trailing, spacing: 4) {
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 52, height: 20)
            .opacity(0.7)

          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 40, height: 14)
            .opacity(0.7)
        }
        .frame(width: 52, alignment: .trailing)
      }

      Spacer()
        .frame(height: 20)

      Path { path in
        path.move(to: CGPoint(x: 0, y: 0.5))
        path.addLine(to: CGPoint(x: 330, y: 0.5))
      }
      .stroke(
        .gray400,
        style: StrokeStyle(
          lineWidth: 1,
          lineCap: .round,
          dash: [1, 4]
        )
      )
      .frame(height: 1)

      Spacer()
        .frame(height: 20)

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 70, height: 12)
            .opacity(0.7)

          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 60, height: 16)
            .opacity(0.7)
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 6) {
          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 50, height: 12)
            .opacity(0.7)

          RoundedRectangle(cornerRadius: 4)
            .fill(.gray300)
            .frame(width: 70, height: 16)
            .opacity(0.7)
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(.gray200)
        .overlay {
          RoundedRectangle(cornerRadius: 24)
            .stroke(.neutral200, style: .init(lineWidth: 1))
        }
    )
  }
}

private extension HistoryItemEntity {
  func toCardItem() -> TravelHistoryCardItem {
    let visitedDate = startTime.toDate() ?? .now
    let departureDate = trainDepartureTime.toDate() ?? .now

    return TravelHistoryCardItem(
      visitedAt: visitedDate,
      placeName: placeName,
      departureName: stationName,
      durationText: "\(totalDurationMinutes)분 소요",
      departureTimeText: departureDate.formattedKoreanTime()
    )
  }
}
