import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeModule(
  name: "Presentation",
  bundleId: .appBundleID(name: ".Presentation"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .Presentation(implements: .Splash),
    .Presentation(implements: .Home),
    .Presentation(implements: .Auth),
    .Presentation(implements: .Profile)
  ],
  sources: ["Sources/**"],
  hasTests: false
)
