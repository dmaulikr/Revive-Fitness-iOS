//
//  ForgotPasswordViewController.swift
//  ReviveFitness
//
//  Created by Dominic Holmes on 8/18/17.
//  Copyright © 2017 Dominic Holmes. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBAction func sendEmailButtonTapped() {
        if emailTextField.hasText {
            Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { (error) in
                if error != nil {
                    self.displayAlert("Error", "Email not sent. Please enter the email address associated with your account and try again.", [""])
                } else {
                    self.displayAlert("Success", "A password reset email has been sent to the email entered.", [""])
                }
            }
        } else {
            displayAlert("Error", "Email not sent. Please enter a valid email address and try again.", [""])
        }
    }
    
    @IBAction func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func displayAlert(_ title: String, _ messageHeader: String, _ errors: [String]) {
        var message = messageHeader
        for eachError in errors {
            message += eachError
        }
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}
