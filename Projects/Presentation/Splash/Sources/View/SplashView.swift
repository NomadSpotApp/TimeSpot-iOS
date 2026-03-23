//
//  SplashView.swift
//  Splash
//
//  Created by Wonji Suh  on 3/1/26.
//

import SwiftUI

import ComposableArchitecture


public struct SplashView: View {
  @Bindable var store: StoreOf<SplashReducer>
  @State private var scale: CGFloat = 1.0
  @State private var bgOpacity: Double = 1.0
  @State private var logoOpacity: Double = 1.0
  @State private var isFinished = false

  public init(store: StoreOf<SplashReducer>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      // 배경
      Color.black
        .opacity(bgOpacity)
        .ignoresSafeArea()

      // 로고
      Text("Uber")
        .font(.system(size: 48, weight: .black))
        .foregroundColor(.white)
        .scaleEffect(scale)
        .opacity(logoOpacity)
    }
    .onAppear {
      // 토큰 확인 시작
      store.send(.view(.onAppear))

      // 1단계: 로고 확대
      withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
        scale = 30.0
      }
      // 2단계: 페이드 아웃
      withAnimation(.easeIn(duration: 0.3).delay(0.7)) {
        logoOpacity = 0
        bgOpacity = 0
      }
      // 3단계: 완료 처리
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
        isFinished = true
      }
    }
  }
}
