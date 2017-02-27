//
//  MenuViewController.swift
//  DDDispatcher
//
//  Created by Woo Jin Kye on 2017. 2. 27..
//  Copyright © 2017년 DD Dispatcher. All rights reserved.
//

import UIKit
import Firebase
//----------------------- Related to Sliding View BEGIN ----------------------
@objc

// Define MenuViewControllerDelegate as a protocol with one required method
protocol MenuViewControllerDelegate {
    func sportSelected(_ url: URL)
}

class MenuViewController:UIViewController, UITableViewDelegate{
    var delegate: MenuViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    // Prepare the view before it appears to the user
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
    }
    // Scroll the selected sport name row towards the middle of the table view
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
    }
    /*
     ----------------------------------------------
     MARK: - UITableViewDataSource Protocol Methods
     ----------------------------------------------
     */
    
    // Asks the data source to return the number of sections in the table view
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    

}
