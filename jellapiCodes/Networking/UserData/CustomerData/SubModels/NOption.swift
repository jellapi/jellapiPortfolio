//
//  NOption.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

class NOption: NSObject {
  var nUrl = ""
  var customized = 0
  var dic: [String: Any]?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    dic = keyedValues
    
    nUrl = json["nUrl"].string ?? ""
    customized = json["customized"].int ?? 0
    
  }
}
