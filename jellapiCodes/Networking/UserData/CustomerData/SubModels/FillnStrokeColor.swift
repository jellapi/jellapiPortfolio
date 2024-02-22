//
//  FillnStrokeColor.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

class FillnStrokeColor: NSObject {
  var fill = ""
  var stroke = ""
  var dic: [String: Any]?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    dic = keyedValues
    
    fill = json["fill"].string ?? ""
    stroke = json["stroke"].string ?? ""
    
  }
}
