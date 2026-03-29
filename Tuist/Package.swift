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
    "WeaveDI": .staticFramework,
    "ReactiveSwift": .staticFramework
  ]
)
#endif

let package = Package(
  name: "TimeSpot",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.23.0"),
    .package(url: "https://github.com/johnpatrickmorgan/TCACoordinators.git", exact: "0.13.0"),
    .package(url: "https://github.com/Roy-wonji/WeaveDI.git", from: "3.4.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.0.0"),
    .package(url: "https://github.com/Roy-wonji/AsyncMoya",  from: "1.1.8"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "2.0.0"),
    .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.7.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.2.0"),
  ]
)
