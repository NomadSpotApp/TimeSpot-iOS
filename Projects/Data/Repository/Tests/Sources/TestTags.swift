//
//  TestTags.swift
//  RepositoryTests
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Testing

// MARK: - Swift Testing Tags
extension Tag {
  @Tag static var unit: Self
  @Tag static var integration: Self
  @Tag static var repository: Self
  @Tag static var route: Self
  @Tag static var success: Self
  @Tag static var error: Self
  @Tag static var performance: Self
  @Tag static var hybrid: Self
}
