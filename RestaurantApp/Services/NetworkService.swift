//
//  NetworkService.swift
//  RestaurantApp
//
//  Created by Jair Moreno Gaspar on 1/9/19.
//  Copyright © 2019 Jair Moreno Gaspar. All rights reserved.
//

import Foundation
import Moya

private let apiKey = "cG5jQSU3Nb3MAX6b9EPPydWPkUKjNTY0lDgb-fAJOQfftIGiYtO1sjCU4o6HmlsAHDOkYORjA2A8QuR0FGl8CAjervtyK7qpwJSPaNLG-nX8JrAjdtz2ODp_8io2XHYx"

enum YelpService {
    
    
    enum BusinessesProvider: TargetType {
        var baseURL: URL{
            return URL(string: "https://api.yelp.com/v3/businesses")!
        }
        
        var path: String {
            switch self {
            case .search:
                return "/search"
            }
        }
        
        var method: Moya.Method {
            return .get
        }
        
        var sampleData: Data {
            return Data()
        }
        
        var task: Task {
            switch self {
            case let .search(lat, long):
                return .requestParameters(parameters: ["latitude": lat, "longitude": long, "limit": 10],
                                          encoding: URLEncoding.queryString)
            }
        }
        
        var headers: [String : String]? {
            return ["Authorization": "Bearer \(apiKey)"]
        }
        
        case search(lat: Double, long: Double)
    }
    
}

