import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Auth",
  bundleId: .appBundleID(name: ".Auth"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [

  .Domain(implements: .UseCase),
  .Shared(implements: .Shared),
  .SPM.composableArchitecture,
  .SPM.tcaCoordinator,
  ],
  sources: ["Sources/**"]
)
