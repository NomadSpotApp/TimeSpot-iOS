//
//  OnBoardingView.swift
//  OnBoarding
//
//  Created by Wonji Suh  on 3/21/26.
//

import SwiftUI
import ComposableArchitecture

import DesignSystem

public struct OnBoardingView: View {
  @Bindable var store: StoreOf<OnBoardingFeature>

  public init(
    store: StoreOf<OnBoardingFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.gray100

      VStack {
        Spacer()
          .frame(height: 20)

        StepOnBoardingView(activeStep: store.activeStep)

        Spacer()


      }
      .padding(.horizontal, 24)
    }
  }
}


extension OnBoardingView {

  @ViewBuilder
  private func StepOnBoardingView(activeStep: Int) -> some View {
    switch activeStep {
      case 1:
        firstStepOnBoardingView()
      case 2:
        secondStepOnBoardingView()
      case 3:
        thirdStepOnBoardingView()
      case  4:
        lastStepOnBoardingView()

      default:
        EmptyView()

    }
  }

  @ViewBuilder
  private func firstStepOnBoardingView() -> some View {
    VStack(alignment: .center) {
      StepNavigationBar(activeStep: store.activeStep)

      Spacer()
        .frame(height: 50)

      HStack(spacing: .zero) {
        Text("열차 출발 전")
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.gray900)

        Text(" 대기 시간,")
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.orange800)
      }

      Text("그냥 보내지 마세요")
        .pretendardCustomFont(textStyle: .heading1)
        .foregroundStyle(.gray900)



      Spacer()
        .frame(height: 12)

      Text("기차를 기다리는 동안 역 주변의")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      Text("다양한 공간을 발견해 보세요.")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      nextStepOnBoardingButton()

    }
  }

  @ViewBuilder
  private func secondStepOnBoardingView() -> some View {
    VStack(alignment: .center) {
      StepNavigationBar(activeStep: store.activeStep)

      Spacer()
        .frame(height: 50)

      Text("남은 시간에 맞는 장소를")
        .pretendardCustomFont(textStyle: .heading1)
        .foregroundStyle(.gray800)

      HStack(spacing: .zero) {
        Text(" 추천")
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.orange800)
        Text("해 드려요")
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.gray900)
      }

      Spacer()
        .frame(height: 12)

      Text("열차 출발까지 남은 시간을 기준으로")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      Text("지금 방문하기 좋은 장소를 추천합니다.")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      nextStepOnBoardingButton()
    }
  }

  @ViewBuilder
  private func thirdStepOnBoardingView() -> some View {
    VStack(alignment: .center) {
      StepNavigationBar(activeStep: store.activeStep)

      Spacer()
        .frame(height: 50)

      HStack(spacing: .zero) {
        Text("열차 시간을 ")
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.gray900)

        Text("놓치지 않도록")
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.orange800)
      }

      Text("안내해 드려요")
        .pretendardCustomFont(textStyle: .heading1)
        .foregroundStyle(.gray900)

      Spacer()
        .frame(height: 12)

      Text("열차 출발 시간을 기준으로 역으로")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      Text("돌아와야 하는 시간을 함께 알려드립니다.")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      nextStepOnBoardingButton()

    }
  }

  @ViewBuilder
  private func lastStepOnBoardingView() -> some View {
    VStack(alignment: .center) {
      StepNavigationBar(activeStep: store.activeStep)
      
      Spacer()
        .frame(height: 50)
      
      Text("사용할 지도 앱을 선택해주세요")
        .pretendardCustomFont(textStyle: .heading1)
        .foregroundStyle(.gray900)

      Spacer()
        .frame(height: 12)

      Text("선택한 지도 앱으로 목적지까지")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      Text("길 안내를 받을 수 있어요.")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.mediumGray)

      nextStepOnBoardingButton()

    }
  }

  @ViewBuilder
  private func nextStepOnBoardingButton() -> some View {
    VStack {
      Spacer()

      CustomButton(
        action: { store.send(.view(.nextStepButtonTapped)) },
        title: store.activeStep == 4 ? "시작하기" : "다음으로"  ,
        config: CustomButtonConfig.create(),
        isEnable: true
      )

      Spacer()
        .frame(height: 32)
    }
  }
}
