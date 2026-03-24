//
//  ToastView.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 12/29/25.
//

import SwiftUI

public struct ToastView: View {
  let toast: ToastType

  public init(toast: ToastType) {
    self.toast = toast
  }

  public var body: some View {
    HStack(spacing: 12) {
      Spacer()
        .frame(width: 8)

      leadingView
      // 메시지
      Text(toast.message)
        .pretendardCustomFont(textStyle: .bodyBold)
        .foregroundColor(.white)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 11)
    .frame(width: 361, height: 56)
    .background(toast.backgroundColor)
    .cornerRadius(30)
    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
  }
}

// MARK: - Toast Overlay Modifier
public struct ToastOverlay: ViewModifier {
  @ObservedObject private var toastManager = ToastManager.shared

  public func body(content: Content) -> some View {
    content
      .overlay(alignment: .top) {
        if let toast = toastManager.currentToast {
          ToastView(toast: toast)
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .opacity(toastManager.isVisible ? 1 : 0)
            .offset(y: toastManager.isVisible ? 0 : -100)
            .transition(.asymmetric(
              insertion: .move(edge: .top).combined(with: .opacity),
              removal: .move(edge: .top).combined(with: .opacity)
            ))
            .allowsHitTesting(toastManager.isVisible)
        }
      }
  }
}

// MARK: - View Extension
public extension View {
  func toastOverlay() -> some View {
    modifier(ToastOverlay())
  }
}

// MARK: - Private views
private extension ToastView {
  @ViewBuilder
  var leadingView: some View {
    switch toast {
      case .loading:
        ProgressView()
          .progressViewStyle(.circular)
          .tint(toast.iconColor)
          .frame(width: 16, height: 16)
      default:
        if let iconName = toast.iconName {
          Image(assetName: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
        }
    }
  }
}

// MARK: - Preview
#Preview {
  VStack(spacing: 20) {
    Button("성공 토스트") {
      ToastManager.shared.showSuccess("로그인에 성공했습니다!")
    }

    Button("에러 토스트") {
      ToastManager.shared.showError("인증에 실패했어요. 다시 시도해주세요..")
    }

    Button("경고 토스트") {
      ToastManager.shared.showWarning("네트워크 연결을 확인해주세요.")
    }

    Button("정보 토스트") {
      ToastManager.shared.showInfo("새로운 업데이트가 있습니다.")
    }
  }
  .padding()
  .toastOverlay()
}
