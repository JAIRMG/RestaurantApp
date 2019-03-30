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
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    
    
    let window = UIWindow()
    let locationService = LocationService()
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let service = MoyaProvider<YelpService.BusinessesProvider>()
    let jsonDecoder = JSONDecoder()
    var navigationController: UINavigationController?

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
        FirebaseApp.configure()
        registerForPushNotifications()
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
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
            self.navigationController = nav
            window.rootViewController = nav
            locationService.getLocation()
            (nav?.topViewController as? RestaurantTableTableViewController)?.delegate = self
        }
        
        window.makeKeyAndVisible()
        
        return true
    }
    
    private func loadDetails(for viewController: UIViewController, withId id: String){
        service.request(.details(id: id)) { [weak self] (result) in
                        switch result{
                            
                        case .success(let response):
                            //Por lo de weak self
                            guard let strongSelf = self else { return }
                            if let details = try? strongSelf.jsonDecoder.decode(Details.self, from: response.data){
                                 print("Detalles \n\n \(details)")
                                let detailsViewModel = DetailsViewModel(details: details)
                                (viewController as? DetailsFoodViewController)?.viewModel = detailsViewModel
                            }
                            
                           
                        case .failure(let error):
                            print("Failed to get details \(error)")
                        }
                    }
    }
    
    private func loadBusinesses(with coordinate: CLLocationCoordinate2D){
        
        service.request(.search(lat: coordinate.latitude, long: coordinate.longitude)) { [weak self] (result) in
            //Por lo de weak self
            guard let strongSelf = self else { return }
            switch result {
            case .success(let response):
                
               
                
                print("Service request \n\n \(try? JSONSerialization.jsonObject(with: response.data, options: []))")
                let root = try? strongSelf.jsonDecoder.decode(Root.self, from: response.data)
                let viewModels = root?.businesses.compactMap(RestaurantListViewModel.init)
                .sorted(by: {$0.distance < $1.distance })
                
                if let nav = strongSelf.window.rootViewController as? UINavigationController,
                    let restaurantListViewController = nav.topViewController as? RestaurantTableTableViewController {
                        restaurantListViewController.viewModels = viewModels ?? []
                } else if let nav = strongSelf.storyboard.instantiateViewController(withIdentifier: "RestaurantNavigationController") as? UINavigationController {
                    strongSelf.navigationController = nav
                    strongSelf.window.rootViewController?.present(nav, animated: true) {
                    (nav.topViewController as? RestaurantTableTableViewController)?.delegate = self
                        (nav.topViewController as? RestaurantTableTableViewController)?.viewModels = viewModels ?? []
                    }
                }
            
                
            case .failure(let error):
                print("Error \(error)")
            }
        }
        
    }
    
    
    //MARK: PUSH NOTIFICATIONS
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
        }

        
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        //TOKEN: 91d05fc2f16c88d548f3200ea186fec55bc8e959ad5e6cf9decc09ed8eb90f1d
        //b6991863f78d6ee8e859afb3402fe8d70da532beee39001308fdb2039023c6c0
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }


    // --- FIREBASE ---
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        
        // Print message ID.
        //    if let messageID = userInfo[gcmMessageIDKey]
        //    {
        //      print("Message ID: \(messageID)")
        //    }
        
        // Print full message.
        print(userInfo)
        
        //    let code = String.getString(message: userInfo["code"])
        guard let aps = userInfo["aps"] as? Dictionary<String, Any> else { return }
        guard let alert = aps["alert"] as? String else { return }
        //    guard let body = alert["body"] as? String else { return }
        
        completionHandler([])
    }

    
    // Handle notification messages after display notification is tapped by the user.
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        print(userInfo)
        completionHandler()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    

}

extension AppDelegate: LocationActions, ListActions {
   
    
    func didTapCell(_ viewController: UIViewController, viewModel: RestaurantListViewModel) {
        loadDetails(for: viewController, withId: viewModel.id)
    }
    
    
    func didTapAllow() {
        locationService.requestLocationAuthorization()
    }
    
    
}
