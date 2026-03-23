//
//  CustomButtonConfig.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 11/2/24.
//

import SwiftUI

public class CustomButtonConfig: TimeSpotCustomButtonConfig {
  static public func create() -> TimeSpotCustomButtonConfig {
    let config = TimeSpotCustomButtonConfig(
      cornerRadius: 30,
      enableFontColor: .gray100,
      enableBackgroundColor: .navy900,
      frameHeight: 60,
      disableFontColor: .gray900,
      disableBackgroundColor: .enableColor
    )
    
    return config
  }
}
