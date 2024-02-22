//
//  UserResponse.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation


struct UserResponse: Codable {
  let id: String
  let roleId: String
  let vendorId: String
  let username: String
  let email: String
  let fullName: String
  let firstName: String
  let lastName: String
  let lastLogin: String
  let verified: Bool
  let active: Bool
  let blocked: Bool
  let deleted: Bool
  let createdUserId: String
  let updatedAt: String
  let createdAt: String
  let tUrl: String
  let iUrl: String
  let invitationCode: String?
  let nIUrl: String?
  let nTUrl: String?
  
  init(id: String,
       roleId: String,
       vendorId: String,
       username: String,
       email: String,
       fullName: String,
       firstName: String,
       lastName: String,
       lastLogin: String,
       verified: Bool,
       active: Bool,
       blocked: Bool,
       deleted: Bool,
       createdUserId: String,
       updatedAt: String,
       createdAt: String,
       tUrl: String,
       iUrl: String,
       invitationCode: String?,
       nIUrl: String?,
       nTUrl: String?) {
    self.id = id
    self.roleId = roleId
    self.vendorId = vendorId
    self.username = username
    self.email = email
    self.fullName = fullName
    self.firstName = firstName
    self.lastName = lastName
    self.lastLogin = lastLogin
    self.verified = verified
    self.active = active
    self.blocked = blocked
    self.deleted = deleted
    self.createdUserId = createdUserId
    self.updatedAt = updatedAt
    self.createdAt = createdAt
    self.tUrl = tUrl
    self.iUrl = iUrl
    self.invitationCode = invitationCode
    self.nIUrl = nIUrl
    self.nTUrl = nTUrl
  }
  
  init(userProfile: UserProfile) {
    self.init(id: userProfile.id,
              roleId: userProfile.roleId,
              vendorId: userProfile.vendorId,
              username: userProfile.username,
              email: userProfile.email,
              fullName: userProfile.fullName,
              firstName: userProfile.firstName,
              lastName: userProfile.lastName,
              lastLogin: userProfile.lastLogin,
              verified: userProfile.verified,
              active: userProfile.active,
              blocked: userProfile.blocked,
              deleted: userProfile.deleted,
              createdUserId: userProfile.createdUserId,
              updatedAt: userProfile.updatedAt,
              createdAt: userProfile.createdAt,
              tUrl: userProfile.tUrl,
              iUrl: userProfile.iUrl,
              invitationCode: userProfile.invitationCode,
              nIUrl: userProfile.nIUrl,
              nTUrl: userProfile.nTUrl)
  }
  
  var userProfile: UserProfile {
    UserProfile(id: id,
                roleId: roleId,
                vendorId: vendorId,
                username: username,
                email: email,
                fullName: fullName,
                firstName: firstName,
                lastName: lastName,
                lastLogin: lastLogin,
                verified: verified,
                active: active,
                blocked: blocked,
                deleted: deleted,
                createdUserId: createdUserId,
                updatedAt: updatedAt,
                createdAt: createdAt,
                tUrl: tUrl,
                iUrl: iUrl,
                invitationCode: invitationCode,
                nIUrl: nIUrl,
                nTUrl: nTUrl)
  }
}
