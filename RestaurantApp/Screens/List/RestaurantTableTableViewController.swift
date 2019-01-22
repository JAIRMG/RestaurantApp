//
//  RestaurantTableTableViewController.swift
//  RestaurantApp
//
//  Created by Jair Moreno Gaspar on 1/3/19.
//  Copyright © 2019 Jair Moreno Gaspar. All rights reserved.
//

import UIKit

protocol ListActions: class {
    func didTapCell(_ viewModel: RestaurantListViewModel)
}

class RestaurantTableTableViewController: UITableViewController {
    
    var viewModels = [RestaurantListViewModel]() {
        didSet{
            tableView.reloadData()
        }
    }
    
    weak var delegate: ListActions?
    
    override func viewDidLoad() {
        super.viewDidLoad()

      
    }

    // MARK: - Table view data source

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return viewModels.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath) as! RestaurantTableViewCell

        // Configure the cell...
        let vm = viewModels[indexPath.row]
        cell.configure(with: vm)

        return cell
    }
 

    //MARK: Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vm = viewModels[indexPath.row]
        delegate?.didTapCell(vm)
    }
    
    
}
