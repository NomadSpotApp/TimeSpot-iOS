
import SwiftUI

import ComposableArchitecture

@main
struct TimeSpotApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      let store = Store(initialState: AppReducer.State()) {
        #if DEBUG
        AppReducer()
          ._printChanges()
          ._printChanges(.actionLabels)
        #else
        AppReducer()
        #endif
      }

      AppView(store: store)
    }
  }
}
