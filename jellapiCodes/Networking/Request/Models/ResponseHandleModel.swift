//
//  ResponseHandleModel.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

struct ServerError: Decodable {
  let field: [String]
  let messages: [String]
  let types: [String]
}

struct Response<T: Decodable>: Decodable {
  let msgCode: String
  let errors: [ServerError]?
  let data: T?
}

enum APIError: Error {
  case response(Body)
  case unknown
  struct Body: Decodable {
    var type: String
    var message: String
  }
}
