//
//  VTIcon.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

class VTIcon: NSObject {
  var id = ""
  var updateAt = ""
  var name = ""
  var src = ""
  var createdAt = ""
  var dic: [String: Any]?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    dic = keyedValues
    id = json["id"].string ?? ""
    updateAt = json["updateAt"].string ?? ""
    name = json["name"].string ?? ""
    src = json["src"].string ?? ""
    createdAt = json["createdAt"].string ?? ""
  }
  
}
