//
//  RxRequest.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/22/24
//  Copyright © 2024 Jellapi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON



class RxRequest: RxRequestProtocol {
  
  static let `default` = RxRequest(
    host: "http://jellapi.net/",
    basePath: "sso/p/saml/login" //ServerApiURL.loginSSOCode()
  )
  
  private let host: String
  private let basePath: String
  
  private init(host: String, basePath: String) {
    self.host = host
    self.basePath = basePath
  }
  
  enum Method: String, CustomStringConvertible {
    case get
    case post
    case put
    case delete
    var description: String { return self.rawValue }
  }
  
  private struct Dummy: Codable {}
  
  func get<U: Decodable>(returnType: U.Type, path: String, query: [String: String]? = nil, headers: [String:String]? = nil) -> Observable<U> {
    return request(.get, U.self, path, query, Dummy?.none, headers)
  }
  func get(path: String, query: [String: String]? = nil, headers: [String:String]? = nil) -> Observable<Void> {
    return request(.get, path, query, Dummy?.none, headers)
  }
  func post<T: Encodable, U: Decodable>(returnType: U.Type, path: String, query: [String: String]? = nil, body: T, headers: [String:String]? = nil) -> Observable<U> {
    return request(.post, U.self, path, query, body, headers)
  }
  func post<T: Encodable>(path: String, query: [String: String]? = nil, body: T, headers: [String:String]? = nil) -> Observable<Void> {
    return request(.post, path, query, body, headers)
  }
  func put<T: Encodable, U: Decodable>(returnType: U.Type, path: String, query: [String: String]? = nil, body: T, headers: [String:String]? = nil) -> Observable<U> {
    return request(.put, U.self, path, query, body, headers)
  }
  func put<T: Encodable>(path: String, query: [String: String]? = nil, body: T, headers: [String:String]? = nil) -> Observable<Void> {
    return request(.put, path, query, body, headers)
  }
  func delete<U: Decodable>(returnType: U.Type, path: String, query: [String: String]? = nil, headers: [String:String]? = nil) -> Observable<U> {
    return request(.delete, U.self, path, query, Dummy?.none, headers)
  }
  func delete(path: String, query: [String: String]? = nil, headers: [String:String]? = nil) -> Observable<Void> {
    return request(.delete, path, query, Dummy?.none, headers)
  }
  
  private func request<T: Encodable, U: Decodable>(_ method: Method, _ returnType: U.Type, _ path: String, _ query: [String: String]?, _ body: T?, _ headers: [String:String]?) -> Observable<U> {
    let req = getURLRequest(method, path, query, body, headers)
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    return session.rx.data(request: req)
      .map { data in
        if "" is U {
          return (String(data: data, encoding: .utf8) ?? "") as! U
        } else {
          let decoder = JSONDecoder()
          do {
            return try decoder.decode(U.self, from: data)
          }
        }
      }
    
  }
  private func request<T: Encodable>(_ method: Method, _ path: String, _ query: [String: String]?, _ body: T?, _ headers: [String:String]?) -> Observable<Void> {
    let req = getURLRequest(method, path, query, body, headers)
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    return session.rx.data(request: req).map { _ in }
  }
  
  private func getURLRequest<Parameters: Encodable>(_ method: Method, _ path: String, _ query: [String: String]?, _ parameters: Parameters?,_ headers: [String:String]?) -> URLRequest {
    var components = URLComponents(string: host + basePath + path)
    if let query = query {
      for (key, value) in query {
        components?.queryItems?.append(URLQueryItem(name: key, value: value))
      }
    }
    guard let url = components?.url else { fatalError("URL is invalid") }
    print(url)
    
    var req = URLRequest(url: url)
    req.httpMethod = method.description
    
    if let headers = headers {
      req.allHTTPHeaderFields = headers
    }
    
    if let parameters = parameters {
      req.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
      let encoder = JSONEncoder()
      do {
        let data = try encoder.encode(parameters)
        req.httpBody = data
      } catch {
        fatalError("Request body is invalid")
      }
    }
    return req
  }
  
  private func getErrorBody<T>(error: Error) throws -> Observable<T> {
    switch error {
    case let RxCocoaURLError.httpRequestFailed(_, data):
      guard let data = data else { throw error }
      guard let body = try? JSONDecoder().decode(APIError.Body.self, from: data) else { throw error }
      throw APIError.response(body)
    default:
      throw error
    }
  }
}
