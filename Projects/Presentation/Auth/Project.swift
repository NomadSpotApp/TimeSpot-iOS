import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin


let project = Project.makeModule(
  name: "Auth",
  bundleId: .appBundleID(name: ".Auth"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .SPM.tcaCoordinator,
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .Presentation(implements: .OnBoarding),
    .Presentation(implements: .Web)
  ],
  sources: ["Sources/**"]
)
