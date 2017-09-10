
import UIKit
import Firebase
import BraintreeDropIn
import Braintree

class ChallengePaymentViewController: UIViewController {
    
    var databaseRef: DatabaseReference!
    var activeUser: ReviveUser?
    var challenge: Challenge?

    var allChallenges: [Challenge]?
    var challengeChoices: [Challenge]?
    
    let toKinizationKey = "sandbox_qxzbjwjj_7b9b5qzp5pjmjtqq"
    
    @IBOutlet weak var paymentRadialView: RadialProgressView!
    @IBOutlet weak var pricetagLabel: UILabel!
    @IBOutlet weak var challengeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var paymentStatusLabel: UILabel!
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var loginScreenButton: UIButton!
    @IBOutlet weak var payButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initializeUIElements()
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func initializeUIElements() {
        if let _ = challenge {
            challengeLabel.text = challenge!.name
        }
        initializeRadialView()
    }
    
    func initializeRadialView() {
        paymentRadialView.progressStroke = pricetagLabel.textColor
        paymentRadialView.createCircles()
    }
    
    func fillRadialView() {
        paymentRadialView.setValueAnimated(duration: 1.0, newProgressValue: 1.0)
    }
    
    func paymentSuccessful() {
        self.activityIndicator.stopAnimating()
        fillRadialView()
        paymentStatusLabel.text = "Payment Complete"
        paymentStatusLabel.textColor = thankYouLabel.textColor
        thankYouLabel.isHidden = false
        loginScreenButton.isHidden = false
        payButton.isEnabled = false
        payButton.backgroundColor = UIColor.lightGray
        
        addUserToChallenge()
    }
    
    func addUserToChallenge() {
        let usersChallengesRef = databaseRef.child("usersChallenges").child(activeUser!.id)
        usersChallengesRef.updateChildValues([challenge!.id: challenge!.name])

        if let _ = self.challengeChoices {
            self.challengeChoices?.append(challenge!)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ReturnToChooseChallenge" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ChooseChallengeTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser!
            controller.challengeChoices = self.challengeChoices!
            controller.allChallenges = self.allChallenges!
        } else if segue.identifier == "ReturnToLogin" {
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch {
            }
        }
    }
    
    @IBAction func returnToLoginButtonPressed() {
        if activeUser != nil && challengeChoices != nil && allChallenges != nil {
            performSegue(withIdentifier: "ReturnToChooseChallenge", sender: self)
        } else {
            performSegue(withIdentifier: "ReturnToLogin", sender: self)
        }
    }
    
    @IBAction func pay(_ sender: Any) {
        // Test Values
        // Card Number: 4111111111111111
        // Expiration: 08/2018
        
        let request =  BTDropInRequest()
        let dropIn = BTDropInController(authorization: toKinizationKey, request: request)
        { [unowned self] (controller, result, error) in
            
            if let error = error {
                self.show(message: error.localizedDescription)
                
            } else if (result?.isCancelled == true) {
                self.show(message: "Transaction Cancelled")
                
            } else if let nonce = result?.paymentMethod?.nonce {
                self.sendRequestPaymentToServer(nonce: nonce, amount: "40")
            }
            controller.dismiss(animated: true, completion: nil)
        }
        
        self.present(dropIn!, animated: true, completion: nil)
    }
    
    func sendRequestPaymentToServer(nonce: String, amount: String) {
        activityIndicator.startAnimating()
        paymentStatusLabel.text = "Processing..."
        
        let paymentURL = URL(string: "https://revive-challenge-backend.herokuapp.com/pay.php")!
        var request = URLRequest(url: paymentURL)
        request.httpBody = "payment_method_nonce=\(nonce)&amount=\(amount)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) -> Void in
            guard let data = data else {
                self?.show(message: error!.localizedDescription)
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let success = result?["success"] as? Bool, success == true else {
                self?.show(message: "Transaction failed. Please try again.")
                return
            }
            
            self?.paymentSuccessful()
            }.resume()
    }
    
    func show(message: String) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.paymentStatusLabel.text = ""
            
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}
