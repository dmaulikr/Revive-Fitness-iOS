//
//  LoginViewController.swift
//  ReviveFitness
//
//  Created by Dominic Holmes on 6/27/17.
//  Copyright © 2017 Dominic Holmes. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var databaseRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseRef = Database.database().reference()
        
        let newUserRef = self.databaseRef.child("users").childByAutoId()
        newUserRef.setValue(["name-first": "Dominic", "name-last": "Holmes", "email": "developer.dominicholmes@gmail.com", "password": "admin1"])
        
        let newUserRef2 = self.databaseRef.child("users").childByAutoId()
        newUserRef2.setValue(["name-first": "Dominic", "name-last": "Holmes", "email": "dh506605@gmail.com", "password": "user1"])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

