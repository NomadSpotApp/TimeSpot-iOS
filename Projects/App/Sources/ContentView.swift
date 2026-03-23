import SwiftUI
import Presentation
import ComposableArchitecture

#Preview("login") {
    LoginView(store:  Store(
        initialState: LoginFeature.State(),
        reducer: {
            LoginFeature()
        }
    ))
}
