//
//  LocationViewController.swift
//  RestaurantApp
//
//  Created by Jair Moreno Gaspar on 1/3/19.
//  Copyright © 2019 Jair Moreno Gaspar. All rights reserved.
//

import UIKit


protocol LocationActions: class {
    func didTapAllow()
}

class LocationViewController: UIViewController {

    @IBOutlet weak var locationView: LocationView!
    weak var delegate: LocationActions?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationView.didTapAllow = {
            print("tap allow")
            self.delegate?.didTapAllow()
            
        }

        

        
        // Do any additional setup after loading the view.
    }
    


}



