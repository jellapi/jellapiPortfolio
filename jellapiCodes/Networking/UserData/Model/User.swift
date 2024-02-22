//
//  User.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation
import SwiftyJSON


class User: NSObject {
  var id = ""
  var username  = ""
  var email     = ""
  var fullName = ""
  var fullNameJa = ""
  var firstName = ""
  var lastName  = ""
  var gender  = ""
  var officeAddress = ""
  var officeDetailAddress = ""
  var officeEmail = ""
  var officeName = ""
  var officePhone = ""
  var officePosition = ""
  var officeWebSite = ""
  var phone = ""
  var alias = ""
  var createdAt: String?
  
  override func setValuesForKeys(_ keyedValues: [String : Any]) {
    let json = JSON(keyedValues)
    id                  = json["id"].string ?? ""
    username            = json["username"].string ?? ""
    email               = json["email"].string ?? ""
    fullName            = json["fullName"].string ?? ""
    fullNameJa          = json["fullNameJa"].string ?? ""
    firstName           = json["firstName"].string ?? ""
    lastName            = json["lastName"].string ?? ""
    gender              = json["gender"].string ?? ""
    officeAddress       = json["officeAddress"].string ?? ""
    officeDetailAddress = json["officeDetailAddress"].string ?? ""
    officeEmail         = json["officeEmail"].string ?? ""
    officeName          = json["officeName"].string ?? ""
    officePhone         = json["officePhone"].string ?? ""
    officePosition      = json["officePosition"].string ?? ""
    officeWebSite       = json["officeWebSite"].string ?? ""
    phone               = json["phone"].string ?? ""
    alias               = json["alias"].string ?? ""
  }
  
}
