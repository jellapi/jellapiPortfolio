//
//  UserData.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation
import SwiftyJSON


class UserData {
  
  static var user:        User?
  static var customerData: CustomerData?
  
  class var accessToken: String? {
    get {
      return UserDefaults.standard.string(forKey: "user_accessToken")
    } set(new) {
      UserDefaults.standard.set(new, forKey: "user_accessToken")
    }
  }
  
  class var refreshToken: String? {
    get {
      return UserDefaults.standard.string(forKey: "user_refreshToken")
    } set(new) {
      UserDefaults.standard.set(new, forKey: "user_refreshToken")
    }
  }
  
  class var storageToken: String? {
    get {
      return UserDefaults.standard.string(forKey: "user_storageToken")
    } set(new) {
      UserDefaults.standard.set(new, forKey: "user_storageToken")
    }
  }
  
  class var user_id: String {
    get {
      return UserDefaults.standard.string(forKey: "user_id") ?? ""
    } set(new) {
      UserDefaults.standard.set(new, forKey: "user_id")
    }
  }
  
  class var email: String? {
    get {
      return UserDefaults.standard.string(forKey: "email")
    } set(new) {
      UserDefaults.standard.set(new, forKey: "email")
    }
  }
  
  class var userDictionary: [String: Any]? {
    get {
      return UserDefaults.standard.dictionary(forKey: "user_userDictionary")
    } set(new) {
      if let dic = new{
        UserDefaults.standard.setValue(dic, forKey: "user_userDictionary")
      }
    }
  }
  
  class func parseUserTokenData(data: [String: Any]) {
    let json = JSON(data)
    UserData.accessToken  = json["tokens"]["accessToken"].string
    UserData.refreshToken = json["tokens"]["refreshToken"].string
    UserData.storageToken = json["tokens"]["storageToken"].string
    UserData.user_id      = json["user"]["user_id"].string ?? ""
    UserData.email        = json["user"]["email"].string
  }
  
  class func setUserDictionary(user: User) {
    var userDictionary: [String: Any]     = [:]
    userDictionary["id"]                  = user.id
    userDictionary["username"]            = user.username
    userDictionary["email"]               = user.email
    userDictionary["firstName"]           = user.firstName
    userDictionary["lastName"]            = user.lastName
    userDictionary["gender"]              = user.gender
    userDictionary["officeAddress"]       = user.officeAddress
    userDictionary["officeDetailAddress"] = user.officeDetailAddress
    userDictionary["officeEmail"]         = user.officeEmail
    userDictionary["officePhone"]         = user.officePhone
    userDictionary["officePosition"]      = user.officePosition
    userDictionary["officeWebSite"]       = user.officeWebSite
    userDictionary["phone"]               = user.phone
    userDictionary["alias"]               = user.alias
    
    userDictionary = userDictionary.reduce(Dictionary(), { (dict, keyValue) in
      let (key, value) = keyValue
      guard !(value is NSNull) else {
        return dict
      }
      var dict = dict
      dict[key] = value
      return dict
    })
    UserData.userDictionary = userDictionary
  }
  
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
  
  class func parseUserPersonalData(data: [String: Any]) {
    guard let userData = data["data"] as? [String: Any]
    else { return }
    
    if let userDic = userData["user"] as? [String : Any] {
      user = User()
      user?.setValuesForKeys(userDic)
      UserData.setUserDictionary(user: user!)
    } else if let userDic = UserData.userDictionary, user == nil {
      user = User()
      user?.setValuesForKeys(userDic)
    }
    
  }
  
}
