//
//  MOptions.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

class MOptions: NSObject {
  var normal: FillnStrokeColor?
  var normal2: FillnStrokeColor?
  var current: FillnStrokeColor?
  var disabled2: FillnStrokeColor?
  var disabled: FillnStrokeColor?
  var customized = false //false
  var dic: [String: Any]?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    dic = keyedValues
    
    if let normalDic = json["normal"].dictionary {
      let normal = FillnStrokeColor()
      normal.setValuesForKeys(normalDic)
      self.normal = normal
    }
    if let normal2Dic = json["normal2"].dictionary {
      let normal2 = FillnStrokeColor()
      normal2.setValuesForKeys(normal2Dic)
      self.normal2 = normal2
    }
    if let currentDic = json["current"].dictionary {
      let current = FillnStrokeColor()
      current.setValuesForKeys(currentDic)
      self.current = current
    }
    if let disabled2Dic = json["disabled2"].dictionary {
      let disabled2 = FillnStrokeColor()
      disabled2.setValuesForKeys(disabled2Dic)
      self.disabled2 = disabled2
    }
    if let disabledDic = json["disabled"].dictionary {
      let disabled = FillnStrokeColor()
      disabled.setValuesForKeys(disabledDic)
      self.disabled = disabled
    }
    
    
    customized = json["customized"].bool ?? false
    
  }
}
