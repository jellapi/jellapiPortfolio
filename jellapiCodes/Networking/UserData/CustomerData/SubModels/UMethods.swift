//
//  UMethods.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

class UMethods: NSObject {
  var bUpload = false
  var iUpload = false
  var dic: [String: Any]?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    dic = keyedValues
    
    bUpload = json["bUpload"].bool ?? false
    iUpload = json["iUpload"].bool ?? false
    
  }
}
