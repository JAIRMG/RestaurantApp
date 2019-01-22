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
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    
    let window = UIWindow()
    let locationService = LocationService()
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let service = MoyaProvider<YelpService.BusinessesProvider>()
    let jsonDecoder = JSONDecoder()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        Testing the details request
//        service.request(.details(id: "WavvLdfdP6g8aZTtbBQHTw")) { (result) in
//            switch result{
//            case .success(let response):
//                let details = try? self.jsonDecoder.decode(Details.self, from: response.data)
//                print("Detalles \n\n \(details)")
//            case .failure(let error):
//                print("Failed to get details \(error)")
//            }
//        }
        
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        locationService.didChangeStatus = { [weak self] success in
            if success {
                self?.locationService.getLocation()
            }
        }
        
        locationService.newLocation = { [weak self] result in
            switch result {
            case .success(let location):
                print("location \(location)")
                self?.loadBusinesses(with: location.coordinate)
            case .failure(let error):
                assertionFailure("Error getting the users location \(error)")
            }
        }
        
        
        switch locationService.status {
        case .denied, .notDetermined, .restricted:
            let locationViewController = storyboard.instantiateViewController(withIdentifier: "LocationViewController") as? LocationViewController
            locationViewController?.delegate = self
            window.rootViewController = locationViewController
        default:
            //assertionFailure()
            let nav = storyboard.instantiateViewController(withIdentifier: "RestaurantNavigationController") as? UINavigationController
            window.rootViewController = nav
            locationService.getLocation()
            (nav?.topViewController as? RestaurantTableTableViewController)?.delegate = self
        }
        
        window.makeKeyAndVisible()
        
        return true
    }
    
    private func loadDetails(withId id: String){
        service.request(.details(id: id)) { [weak self] (result) in
                        switch result{
                            
                        case .success(let response):
                            //Por lo de weak self
                            guard let strongSelf = self else { return }
                            let details = try? strongSelf.jsonDecoder.decode(Details.self, from: response.data)
                            print("Detalles \n\n \(details)")
                        case .failure(let error):
                            print("Failed to get details \(error)")
                        }
                    }
    }
    
    private func loadBusinesses(with coordinate: CLLocationCoordinate2D){
        
        service.request(.search(lat: coordinate.latitude, long: coordinate.longitude)) { [weak self] (result) in
            switch result {
            case .success(let response):
                
                //Por lo de weak self
                guard let strongSelf = self else { return }
                
                print("Service request \n\n \(try? JSONSerialization.jsonObject(with: response.data, options: []))")
                let root = try? strongSelf.jsonDecoder.decode(Root.self, from: response.data)
                print("root: \n\n \(root)")
                let viewModels = root?.businesses.compactMap(RestaurantListViewModel.init)
                .sorted(by: {$0.distance < $1.distance })
                
                if let nav = strongSelf.window.rootViewController as? UINavigationController,
                let restaurantListViewController = nav.topViewController as? RestaurantTableTableViewController {
                    restaurantListViewController.viewModels = viewModels ?? []
                }
                
            case .failure(let error):
                print("Error \(error)")
            }
        }
        
    }
    

}

extension AppDelegate: LocationActions, ListActions {
    func didTapCell(_ viewModel: RestaurantListViewModel) {
        loadDetails(withId: viewModel.id)
    }
    
    func didTapAllow() {
        locationService.requestLocationAuthorization()
    }
    
    
}
