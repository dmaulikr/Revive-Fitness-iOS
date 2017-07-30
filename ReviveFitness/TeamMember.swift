
import Foundation

class TeamMember: NSObject {
    
    let name: String!
    let id: String!
    private var didSubmitToday = false
    private var scoreForThisWeek = 0
    private var needsUpdate = false
    
    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
    
    func shouldUpdateRadialViews() -> Bool {
        if needsUpdate {
            needsUpdate = false
            return true
        } else {
            return false
        }
    }
    
    func getValueDidSubmitToday() -> Bool {
        return didSubmitToday
    }
    
    func setValueDidSubmitToday(with value: Bool) {
        if value != didSubmitToday {
            needsUpdate = true
            didSubmitToday = value
        }
    }
    
    func getValueScoreForThisWeek() -> Int {
        return scoreForThisWeek
    }
    
    func setValueScoreForThisWeek(with value: Int) {
        if value != scoreForThisWeek {
            needsUpdate = true
            scoreForThisWeek = value
        }
    }
}
