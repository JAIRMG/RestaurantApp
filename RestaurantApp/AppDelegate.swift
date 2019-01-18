//
//  AppDelegate.swift
//  RestaurantApp
//
//  Created by Jair Moreno Gaspar on 1/2/19.
//  Copyright © 2019 Jair Moreno Gaspar. All rights reserved.
//
//lat=19.364789
//long=-99.174246

import UIKit
import Moya

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    
    let window = UIWindow()
    let locationService = LocationService()
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let service = MoyaProvider<YelpService.BusinessesProvider>()
    let jsonDecoder = JSONDecoder()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        

        
        switch locationService.status {
        case .denied, .notDetermined, .restricted:
            let locationViewController = storyboard.instantiateViewController(withIdentifier: "LocationViewController") as? LocationViewController
            locationViewController?.locationService = locationService
            window.rootViewController = locationViewController
        default:
            //assertionFailure()
            let nav = storyboard.instantiateViewController(withIdentifier: "RestaurantNavigationController") as? UINavigationController
            window.rootViewController = nav
            loadBusinesses()
        }
        
        window.makeKeyAndVisible()
        
        return true
    }
    
    private func loadBusinesses(){
        
        service.request(.search(lat: 19.364789, long: -99.174246)) { (result) in
            switch result {
            case .success(let response):
                print(try? JSONSerialization.jsonObject(with: response.data, options: []))
                let root = try? self.jsonDecoder.decode(Root.self, from: response.data)
                print("root: \(root)")
                let viewModels = root?.businesses.compactMap(RestaurantListViewModel.init)
                
                if let nav = self.window.rootViewController as? UINavigationController,
                let restaurantListViewController = nav.topViewController as? RestaurantTableTableViewController {
                    restaurantListViewController.viewModels = viewModels ?? []
                }
                
            case .failure(let error):
                print("Error \(error)")
            }
        }
        
    }
    

}

