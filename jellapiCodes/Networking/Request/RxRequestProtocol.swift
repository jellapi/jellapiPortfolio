//
//  RxRequestProtocol.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation

protocol RxRequestProtocol {
  func get<U: Decodable>(returnType: U.Type, path: String, query: [String: String]?, headers: [String:String]?) -> Observable<U>
  func get(path: String, query: [String: String]?, headers: [String:String]?) -> Observable<Void>
  func post<T: Encodable, U: Decodable>(returnType: U.Type, path: String, query: [String: String]?, body: T, headers: [String:String]?) -> Observable<U>
  func post<T: Encodable>(path: String, query: [String: String]?, body: T, headers: [String:String]?) -> Observable<Void>
  func put<T: Encodable, U: Decodable>(returnType: U.Type, path: String, query: [String: String]?, body: T, headers: [String:String]?) -> Observable<U>
  func put<T: Encodable>(path: String, query: [String: String]?, body: T, headers: [String:String]?) -> Observable<Void>
  func delete<U: Decodable>(returnType: U.Type, path: String, query: [String: String]?, headers: [String:String]?) -> Observable<U>
  func delete(path: String, query: [String: String]?, headers: [String:String]?) -> Observable<Void>
}
