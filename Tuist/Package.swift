// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
  productTypes: [
    "ComposableArchitecture": .staticFramework,
    "TCACoordinators": .staticFramework,
    "Moya": .staticFramework,
    "LogMacro": .staticFramework,
    "AsyncMoya": .staticFramework,
    "AppAuth": .staticFramework,
    "AppAuthCore": .staticFramework,
    "GTMAppAuth": .staticFramework,
    "GTMSessionFetcherCore": .staticFramework,
    "IssueReporting": .staticFramework,
    "IssueReportingPackageSupport": .staticFramework,
    "XCTestDynamicOverlay": .staticFramework,
    "Clocks": .staticFramework,
    "ConcurrencyExtras": .staticFramework,
    "SDWebImageSwiftUI": .staticFramework,
    "WeaveDI": .staticFramework
  ]
)
#endif

let package = Package(
  name: "MultiModuleTemplate",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.18.0"),
    .package(url: "https://github.com/johnpatrickmorgan/TCACoordinators.git", exact: "0.11.1"),
    .package(url: "https://github.com/Roy-wonji/WeaveDI.git", from: "3.4.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.0.0"),
    .package(url: "https://github.com/Roy-wonji/AsyncMoya",  from: "1.1.8"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "2.0.0"),
  ]
)
