
import Foundation

class TeamMember: NSObject {
    
    let name: String!
    let id: String!
    private var didSubmitToday = false
    private var scoresForThisWeek = [0, 0, 0, 0, 0, 0, 0]
    private var historicalScoresForThisWeek = [0, 0, 0, 0, 0, 0, 0]
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
    // Did submit
    func getValueDidSubmitToday() -> Bool {
        return didSubmitToday
    }
    
    func setValueDidSubmitToday(with value: Bool) {
        if value != didSubmitToday {
            needsUpdate = true
            didSubmitToday = value
        }
    }
    
    // This week's scores
    func getValueScoreForThisWeek() -> Int {
        var temp = 0
        for eachScore in scoresForThisWeek {
            temp += eachScore
        }
        return temp
    }
    
    func getValueScore(forDay day: Int) -> Int {
        return scoresForThisWeek[day]
    }
    
    func setValueScore(forDay day: Int, toValue value: Int) {
        if scoresForThisWeek[day] != value {
            needsUpdate = true
            scoresForThisWeek[day] = value
        }
    }
    
    // Last week's scores
    func setHistoricalValueScore(forDay day: Int, toValue value: Int) {
        if historicalScoresForThisWeek[day] != value {
            needsUpdate = true
            historicalScoresForThisWeek[day] = value
        }
    }
    
    func getHistoricalValueScore(forDay day: Int) -> Int {
        return historicalScoresForThisWeek[day]
    }
}
