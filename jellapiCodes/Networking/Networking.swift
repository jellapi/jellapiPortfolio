//
//  Networking.swift
//
//  Created by Jellapi on 2/3/24.
//  Copyright © 2024 Jellapi. All rights reserved.
//
//test

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON




class testClass: NSObject {
  let disposedBag = DisposeBag()

  func testRequest(vID: String, code: String) {
    let headers = [
      "User-Agent": UserAgent.getUserAgent(),
      "vID": vID]
    let req = RxRequest.default.post(returnType:UserResponse.self, path: "/\(vID)", body: ["code": code], headers: headers)
    req.subscribe(onNext: { userRes in
      print("\(userRes.fullName)")
      // JSon type
//      if let data = result["data"] as? [String: Any] {
//        UserData.parseUserTokenData(data: data)
//        UserData.parseUserPersonalData(data: result)
//      }
    }).disposed(by: disposedBag)
  }
}
