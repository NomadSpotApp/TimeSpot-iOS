//
//  Project+Template.swift
//  MyPlugin
//
//  Created by Wonji Suh on 1/6/24.
//

import ProjectDescription
import Foundation

// MARK: - Suppress Warnings Setting
private let suppressWarningsSettings: ProjectDescription.Settings = .settings(
  base: ["OTHER_SWIFT_FLAGS": "$(inherited) -suppress-warnings"]
)

// MARK: - Helper Functions
private func ensureTestsSourcesDirectoryExists(for projectName: String) {
    let fileManager = FileManager.default

    // Try to find the current module directory
    let currentDirectory = fileManager.currentDirectoryPath
    let possiblePaths = [
        "\(currentDirectory)/Tests/Sources",
        "./Tests/Sources"
    ]

    for testsSourcesPath in possiblePaths {
        let parentDir = URL(fileURLWithPath: testsSourcesPath).deletingLastPathComponent().path

        if fileManager.fileExists(atPath: parentDir) || parentDir == "." {
            if !fileManager.fileExists(atPath: testsSourcesPath) {
                do {
                    try fileManager.createDirectory(atPath: testsSourcesPath, withIntermediateDirectories: true, attributes: nil)
                    print("📁 Created Tests/Sources directory for \(projectName) at \(testsSourcesPath)")
                    return
                } catch {
                    print("⚠️  Failed to create Tests/Sources directory for \(projectName) at \(testsSourcesPath): \(error)")
                }
            } else {
                return // Directory already exists
            }
        }
    }
}

public extension Project {
  static func makeAppModule(
    name: String = Environment.appName,
    bundleId: String,
    platform: Platform = .iOS,
    product: Product,
    packages: [Package] = [],
    deploymentTarget: ProjectDescription.DeploymentTargets = Environment.deploymentTarget,
    destinations: ProjectDescription.Destinations = Environment.deploymentDestination,
    settings: ProjectDescription.Settings,
    scripts: [ProjectDescription.TargetScript] = [],
    dependencies: [ProjectDescription.TargetDependency] = [],
    sources: ProjectDescription.SourceFilesList = ["Sources/**"],
    resources: ProjectDescription.ResourceFileElements? = nil,
    infoPlist: ProjectDescription.InfoPlist = .default,
    entitlements: ProjectDescription.Entitlements? = nil,
    schemes: [ProjectDescription.Scheme] = [],
    hasTests: Bool = false
  ) -> Project {

    let appTarget: Target = .target(
      name: name,
      destinations: destinations,
      product: product,
      bundleId: bundleId,
      deploymentTargets: deploymentTarget,
      infoPlist: infoPlist,
      sources: sources,
      resources: resources,
      entitlements: entitlements,
      scripts: scripts,
      dependencies: dependencies,
      settings: suppressWarningsSettings
    )

    let appProdTarget: Target = .target(
      name: "\(name)-Prod",
      destinations: destinations,
      product: product,
      bundleId: "\(bundleId)",
      deploymentTargets: deploymentTarget,
      infoPlist: infoPlist,
      sources: sources,
      resources: resources,
      entitlements: entitlements,
      scripts: scripts,
      dependencies: dependencies,
      settings: suppressWarningsSettings
    )


    let appStageTarget: Target = .target(
      name: "\(name)-Stage",
      destinations: destinations,
      product: product,
      bundleId: "\(bundleId)",
      deploymentTargets: deploymentTarget,
      infoPlist: infoPlist,
      sources: sources,
      resources: resources,
      entitlements: entitlements,
      scripts: scripts,
      dependencies: dependencies,
      settings: suppressWarningsSettings
    )


    let appDevTarget: Target = .target(
      name: "\(name)-Debug",
      destinations: destinations,
      product: product,
      bundleId: "\(bundleId)",
      deploymentTargets: deploymentTarget,
      infoPlist: infoPlist,
      sources: sources,
      resources: resources,
      entitlements: entitlements,
      scripts: scripts,
      dependencies: dependencies,
      settings: suppressWarningsSettings
    )

    var targets: [Target] = [appTarget, appDevTarget, appStageTarget, appProdTarget]

    if hasTests {
        // Ensure Tests/Sources directory exists
        ensureTestsSourcesDirectoryExists(for: name)

        let appTestTarget : Target = .target(
          name: "\(name)Tests",
          destinations: destinations,
          product: .unitTests,
          bundleId: "\(bundleId).\(name)Tests",
          deploymentTargets: deploymentTarget,
        infoPlist: .default,
        sources: ["Tests/Sources/**"],
        dependencies: [.target(name: name)],
        settings: suppressWarningsSettings
      )
      targets.append(appTestTarget)
    }

    return Project(
      name: name,
      options: .options(
        defaultKnownRegions: ["en", "ko"],
        developmentRegion: "ko"
      ),
      packages: packages,
      settings: settings,
      targets: targets,
      schemes: schemes
    )
  }

  static func makeModule(
    name: String = Environment.appName,
    bundleId: String,
    platform: Platform = .iOS,
    product: Product,
    packages: [Package] = [],
    deploymentTarget: ProjectDescription.DeploymentTargets = Environment.deploymentTarget,
    destinations: ProjectDescription.Destinations = Environment.deploymentDestination,
    settings: ProjectDescription.Settings,
    scripts: [ProjectDescription.TargetScript] = [],
    dependencies: [ProjectDescription.TargetDependency] = [],
    sources: ProjectDescription.SourceFilesList = ["Sources/**"],
    testSources: ProjectDescription.SourceFilesList = ["Tests/Sources/**"],
    resources: ProjectDescription.ResourceFileElements? = nil,
    infoPlist: ProjectDescription.InfoPlist = .default,
    entitlements: ProjectDescription.Entitlements? = nil,
    schemes: [ProjectDescription.Scheme] = [],
    hasTests: Bool = false
  ) -> Project {

    let appTarget: Target = .target(
      name: name,
      destinations: destinations,
      product: product,
      bundleId: bundleId,
      deploymentTargets: deploymentTarget,
      infoPlist: infoPlist,
      sources: sources,
      resources: resources,
      entitlements: entitlements,
      scripts: scripts,
      dependencies: dependencies,
      settings: suppressWarningsSettings
    )

    var targets: [Target] = [appTarget]

    if hasTests {
      // Ensure Tests/Sources directory exists
      ensureTestsSourcesDirectoryExists(for: name)

      let appTestTarget : Target = .target(
        name: "\(name)Tests",
        destinations: destinations,
        product: .unitTests,
        bundleId: "\(bundleId).\(name)Tests",
        deploymentTargets: deploymentTarget,
        infoPlist: .default,
        sources: testSources,
        dependencies: [.target(name: name)],
        settings: suppressWarningsSettings
      )
      targets.append(appTestTarget)
    }

    return Project(
      name: name,
      packages: packages,
      settings: settings,
      targets: targets,
      schemes: schemes
    )
  }
}



extension Scheme {
  public static func makeScheme(target configuration: ConfigurationName, name: String) -> Scheme {
    return Scheme.scheme(
      name: name,
      shared: true,
      buildAction: .buildAction(
        targets: [.target(name)]
      ),
      testAction: .targets(
        ["\(name)Tests"],
        configuration: configuration,
        options: .options(
          coverage: true,
          codeCoverageTargets: [.target(name)]
        )
      ),
      runAction: .runAction(configuration: configuration),
      archiveAction: .archiveAction(configuration: configuration),
      profileAction: .profileAction(configuration: configuration),
      analyzeAction: .analyzeAction(configuration: configuration)
    )
  }

  public static func makeTestPlanScheme(target: ConfigurationName, name: String) -> Scheme {
    return Scheme.scheme(
      name: name,
      shared: true,
      buildAction: .buildAction(targets: ["\(name)", "\(name)Tests"]),
      testAction: .testPlans(["\(name)Tests/Sources/\(name)TestPlan.xctestplan"]),
      runAction: .runAction(configuration: "Debug"),
      archiveAction: .archiveAction(configuration: "Debug"),
      profileAction: .profileAction(configuration: "Debug"),
      analyzeAction: .analyzeAction(configuration: "Debug")
    )
  }
}


public extension Scheme {
    static func scheme(name: String, environment: ConfigurationEnvironment) -> Scheme {
        let appName = Project.Environment.appName
        let schemeName: String = (environment == .prod)
            ? appName
            : "\(appName)-\(environment.name)"

      return Scheme.scheme(
            name: schemeName,
            shared: true,
            buildAction: .buildAction(
              targets: [.target(name)]
            ),
            testAction: 
                .targets(
                  ["\(name)Tests"],
                  configuration: environment.configurationName,
                  options:.options(
                    coverage: true,
                    codeCoverageTargets: [.target(name)]
                  )
            ),
            runAction: .runAction(configuration: environment.configurationName),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: environment.configurationName)
        )
    }
}
