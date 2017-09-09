
import UIKit
import Firebase

class ChallengePaymentViewController: UIViewController {
    
    var databaseRef: DatabaseReference!
    var activeUser: ReviveUser?
    var challenge: Challenge?
    
    @IBOutlet weak var paymentRadialView: RadialProgressView!
    @IBOutlet weak var pricetagLabel: UILabel!
    @IBOutlet weak var challengeLabel: UILabel!
    
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
    
}
