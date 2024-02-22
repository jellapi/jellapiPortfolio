//
//  GMOption.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

class GMOption: NSObject {
  var styles: Any?
  var customized = false
  var dic: [String: Any]?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    dic = keyedValues
    
    styles = json["styles"].object
    customized = json["customized"].bool ?? false
    
  }
}
