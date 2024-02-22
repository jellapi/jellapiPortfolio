//
//  CustomerData.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/21/24
//  Copyright © 2024 Jellapi. All rights reserved.
//


import Foundation

class CustomerData: NSObject {
  var tagIcons: [VTIcon]?
  var iEncrypt = 0
  var nOption: NOption?
  var lScreen: LScreen?
  var uMethods: UMethods?
  var tOptions: TOptions?
  var rColor: RColor?
  var mOptions: MOptions?
  var gMOption: GMOption?
  var iUpload = 0
  var tFDistance = 0
  
  var dic: [String: Any]?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    dic = keyedValues
    
    tagIcons  = json["VTIcon"].array?.compactMap({ (json) -> VTIcon? in
      guard let dicObj = json.dictionaryObject else { return nil }
      let tIcon = VTIcon()
      tIcon.setValuesForKeys(dicObj)
      return tIcon
    })
    
    iEncrypt = json["iEncrypt"].int ?? 0
    
    if let nOptionDic = json["nOption"].dictionary {
      let nOption = NOption()
      nOption.setValuesForKeys(nOptionDic)
      self.nOption = nOption
    }
    if let lScreenDic = json["lScreen"].dictionary {
      let lScreen = LScreen()
      lScreen.setValuesForKeys(lScreenDic)
      self.lScreen = lScreen
    }
    if let uploadMethodDic = json["uMethods"].dictionary {
      let uMethods = UMethods()
      uMethods.setValuesForKeys(uploadMethodDic)
      self.uMethods = uMethods
    }
    if let tOptionsDic = json["tOptions"].dictionary {
      let tOptions = TOptions()
      tOptions.setValuesForKeys(tOptionsDic)
      self.tOptions = tOptions
    }
    if let rColorDic = json["rColor"].dictionary {
      let rColor = RColor()
      rColor.setValuesForKeys(rColorDic)
      self.rColor = rColor
    }
    if let mOptionsDic = json["mOptions"].dictionary {
      let mOptions = MOptions()
      mOptions.setValuesForKeys(mOptionsDic)
      self.mOptions = mOptions
    }
    if let gMOptionDic = json["gMOption"].dictionary {
      let gMOption = GMOption()
      gMOption.setValuesForKeys(gMOptionDic)
      self.gMOption = gMOption
    }
    
    iUpload = json["iUpload"].int ?? 0
    tFDistance = json["tFDistance"].int ?? 0
    
  }
}

