//
//  CustomButtonConfig.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 11/2/24.
//

import SwiftUI

public class CustomButtonConfig: DDDCustomButtonConfig {
  static public func create() -> DDDCustomButtonConfig {
    let config = DDDCustomButtonConfig(
      cornerRadius: 30,
      enableFontColor: .gray100,
      enableBackgroundColor: .navy900,
      frameHeight: 60,
      disableFontColor: .gray900,
      disableBackgroundColor: .enableColor
    )
    
    return config
  }
  
  static public func createDateButton() -> DDDCustomButtonConfig {
    let config = DDDCustomButtonConfig(
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
