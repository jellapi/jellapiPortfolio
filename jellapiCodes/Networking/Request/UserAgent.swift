//
//  UserAgent.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/21/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation
import UIKit


class UserAgent {
  static func getUserAgent() -> String {
    let bundleDict = Bundle.main.infoDictionary!
    let appVersion = bundleDict["CFBundleShortVersionString"] as! String
    let appDescriptor = "Jellapi/\(appVersion)"
    let currentDevice = UIDevice.current
    let osDescriptor = "iOS/" + currentDevice.systemVersion
    let hardwareString = self.getHardwareString()
    return appDescriptor + " " + osDescriptor + " (" + hardwareString + ")"
  }
  
  static func getHardwareString() -> String {
    var name: [Int32] = [CTL_HW, HW_MACHINE]
    var unknown: [Int] = []
    var size: Int = 2
    sysctl(&name, 2, nil, &size, &unknown, 0)
    var hw_machine = [CChar](repeating: 0, count: Int(size))
    sysctl(&name, 2, &hw_machine, &size, &unknown, 0)
    
    let hardware: String = String(cString: hw_machine)
    return hardware
  }
}

extension UserAgent: UserAgentProvider {
  func getUserAgent() -> String {
    UserAgent.getUserAgent()
  }
}

public protocol UserAgentProvider {
  func getUserAgent() -> String
}
