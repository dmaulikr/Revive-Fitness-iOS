// Dominic Holmes - 8/2/2017

import UIKit

class DataPointGraphView: UIView {
    
    var primaryDataColor = UIColor(red: 4.0 / 255.0, green: 169 / 255.0, blue: 235.0 / 255.0, alpha: 1.0)
    var primaryLineColor = UIColor(red: 4.0 / 255.0, green: 169 / 255.0, blue: 235.0 / 255.0, alpha: 0.5)
    let axisColor = UIColor(white: 0.9, alpha: 1.0)
    let labelColor = UIColor.darkGray
    let secondaryDataColor = UIColor.lightGray
    
    var viewHeight: CGFloat!
    var viewWidth: CGFloat!
    var graphHeight: CGFloat!
    var graphWidth: CGFloat!
    var graphFrame: CGRect!
    
    var dataMax: CGFloat!
    var dataMin: CGFloat!
    var dataRange: CGFloat!
    
    var dataToGraph: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var secondaryDataToGraph: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var xAxisLabels: [String] = ["M", "T", "W", "T", "F", "S", "S"]
    
    var finalDataCoordinates: [CGPoint] = [CGPoint]()
    var startingDataCoordinates: [CGPoint] = [CGPoint]()
    
    var dataCircles: [CAShapeLayer] = [CAShapeLayer]()
    var dataCirclesFinalPaths: [CGPath] = [CGPath]()
    
    var dataConnectingLines: [CAShapeLayer] = [CAShapeLayer]()
    var dataConnectingLinesFinalPaths: [CGPath] = [CGPath]()
    
    var axisLines: [CAShapeLayer] = [CAShapeLayer]()
    var axisLabels: [UILabel] = [UILabel]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initializeGraph() {
        initializeGraphFrame()
        drawGraphAxis()
        initializeDataGraphics()
    }
    
    func initializeGraphFrame() {
        self.viewHeight = self.frame.height
        self.viewWidth = self.frame.width
        self.graphHeight = (0.5 * self.frame.height)
        self.graphWidth = (0.8 * self.frame.width)
        self.graphFrame = CGRect(x: 0.0 + ((viewWidth - graphWidth) / 2.0) + 10.0,
                                 y: 0.0 + ((viewHeight - graphHeight) / 2.0) + (graphHeight * 0.1),
                                 width: graphWidth, height: graphHeight)
        
        let dataMaxPrimary = self.dataToGraph.max()
        let dataMinPrimary = self.dataToGraph.min()
        let dataMaxSecondary = self.secondaryDataToGraph.max()
        let dataMinSecondary = self.secondaryDataToGraph.min()
        
        if dataMaxPrimary! > dataMaxSecondary! {
            self.dataMax = CGFloat(dataMaxPrimary!)
        } else {
            self.dataMax = CGFloat(dataMaxSecondary!)
        }
        
        if dataMinPrimary! < dataMinSecondary! {
            self.dataMin = CGFloat(dataMinPrimary!)
        } else {
            self.dataMin = CGFloat(dataMinSecondary!)
        }
        self.dataRange = self.dataMax - self.dataMin
        if dataRange == 0 {
            self.dataMin = 0
            self.dataMax = 100
            self.dataRange = 100
        }
    }
    
    // Populate the graph with circles representing datapoints
    
    func initializeDataGraphics() {
        findDataCoordinates()
        drawDataLines()
        drawDataPoints()
    }
    
    func findDataCoordinates() {
        var tempDataCoordinates = [CGPoint]()
        var tempStartingDataCoordinates = [CGPoint]()
        
        let xInterval = (graphWidth) / CGFloat(dataToGraph.count + 1)
        
        for eachPoint in secondaryDataToGraph.indices {
            let valueOfPoint = secondaryDataToGraph[eachPoint]
            let xCoordinate = graphFrame.origin.x + (xInterval * CGFloat(eachPoint + 1))
            let yCoordinate = graphFrame.origin.y + graphHeight -
                ((CGFloat(valueOfPoint) - dataMin) * (graphHeight / dataRange))
            tempDataCoordinates.append(CGPoint(x: xCoordinate, y: yCoordinate))
            tempStartingDataCoordinates.append(CGPoint(x: xCoordinate,
                                                       y: graphFrame.origin.y + graphHeight))
        }
        for eachPoint in dataToGraph.indices {
            let valueOfPoint = dataToGraph[eachPoint]
            let xCoordinate = graphFrame.origin.x + (xInterval * CGFloat(eachPoint + 1))
            let yCoordinate = graphFrame.origin.y + graphHeight -
                ((CGFloat(valueOfPoint) - dataMin) * (graphHeight / dataRange))
            tempDataCoordinates.append(CGPoint(x: xCoordinate, y: yCoordinate))
            tempStartingDataCoordinates.append(CGPoint(x: xCoordinate,
                                                       y: graphFrame.origin.y + graphHeight))
        }
        finalDataCoordinates = tempDataCoordinates
        startingDataCoordinates = tempStartingDataCoordinates
        
    }
    
    func drawDataLines() {
        dataConnectingLines = [CAShapeLayer]()
        for eachPoint in secondaryDataToGraph.indices {
            if eachPoint != 0 {
                dataConnectingLines.append(
                    addLine(
                        fromPoint: startingDataCoordinates[eachPoint - 1],
                        toPoint: startingDataCoordinates[eachPoint],
                        ofColor: secondaryDataColor.cgColor)!)
                let finalPath = UIBezierPath()
                finalPath.move(to: finalDataCoordinates[eachPoint - 1])
                finalPath.addLine(to: finalDataCoordinates[eachPoint])
                dataConnectingLinesFinalPaths.append(finalPath.cgPath)
            }
        }
        for eachPoint in dataToGraph.indices {
            let offset = secondaryDataToGraph.count
            if eachPoint != 0 {
                dataConnectingLines.append(
                    addLine(
                        fromPoint: startingDataCoordinates[eachPoint - 1 + offset],
                        toPoint: startingDataCoordinates[eachPoint + offset],
                        ofColor: primaryLineColor.cgColor)!)
                let finalPath = UIBezierPath()
                finalPath.move(to: finalDataCoordinates[eachPoint - 1 + offset])
                finalPath.addLine(to: finalDataCoordinates[eachPoint + offset])
                dataConnectingLinesFinalPaths.append(finalPath.cgPath)
            }
        }
    }
    
    func drawDataPoints() {
        dataCircles = [CAShapeLayer]()
        for eachPoint in secondaryDataToGraph.indices {
            dataCircles.append(
                addCircle(at: startingDataCoordinates[eachPoint],
                          ofColor: secondaryDataColor.cgColor))
            let finalCirclePath = getCirclePath(at: finalDataCoordinates[eachPoint])
            dataCirclesFinalPaths.append(finalCirclePath)
        }
        let offset = secondaryDataToGraph.count
        for eachPoint in dataToGraph.indices {
            dataCircles.append(
                addCircle(at: startingDataCoordinates[eachPoint + offset],
                          ofColor: primaryDataColor.cgColor))
            let finalCirclePath = getCirclePath(at: finalDataCoordinates[eachPoint + offset])
            dataCirclesFinalPaths.append(finalCirclePath)
        }
    }
    
    // Create the axis of the graph
    
    func drawGraphAxis() {
        var tempAxisLines: [CAShapeLayer] = [CAShapeLayer]()
        tempAxisLines.append(addLine(fromPoint: CGPoint(x: graphFrame.origin.x, y: graphFrame.origin.y),
                                 toPoint: CGPoint(x: graphFrame.origin.x + graphWidth, y: graphFrame.origin.y),
                                 ofColor: axisColor.cgColor)!)
        
        tempAxisLines.append(addLine(fromPoint: CGPoint(x: graphFrame.origin.x, y: graphFrame.origin.y + 0.5 * graphHeight),
                                 toPoint: CGPoint(x: graphFrame.origin.x + graphWidth, y: graphFrame.origin.y + 0.5 * graphHeight),
                                 ofColor: axisColor.cgColor)!)
        
        tempAxisLines.append(addLine(fromPoint: CGPoint(x: graphFrame.origin.x, y: graphFrame.origin.y + graphHeight),
                                 toPoint: CGPoint(x: graphFrame.origin.x + graphWidth, y: graphFrame.origin.y + graphHeight),
                                 ofColor: axisColor.cgColor)!)
        self.axisLines = tempAxisLines
        self.axisLabels = [UILabel]()
        generateAxisXLabels()
        generateAxisYLabels()
    }
    
    // Functions that create basic objects
    
    func addLine(fromPoint start: CGPoint, toPoint end: CGPoint, ofColor color: CGColor) -> CAShapeLayer? {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = color
        line.lineWidth = 1
        line.lineJoin = kCALineJoinRound
        self.layer.addSublayer(line)
        return line
    }
    
    func addCircle(at point: CGPoint, ofColor color: CGColor) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = getCirclePath(at: point)
        shapeLayer.fillColor = color
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 3.0
        
        self.layer.addSublayer(shapeLayer)
        return shapeLayer
    }
    
    func getCirclePath(at point: CGPoint) -> CGPath {
        return UIBezierPath(
            arcCenter: point,
            radius: CGFloat(3.0),
            startAngle: CGFloat(0),
            endAngle:CGFloat(Double.pi * 2),
            clockwise: true).cgPath
    }
    
    func createLabel(fromString text: String!, insideRect rect: CGRect, onAxis axis: String) -> UILabel {
        let labelString = NSMutableAttributedString(
            string: text,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightUltraLight)])
        let newLabel = UILabel(frame: rect)
        newLabel.attributedText = labelString
        newLabel.textColor = labelColor
        if axis == "y" { newLabel.textAlignment = .right } else { newLabel.textAlignment = .left }
        self.addSubview(newLabel)
        return newLabel
    }
    
    // Create labels for the axes
    
    func generateAxisYLabels() {
        axisLabels.append(createLabel(fromString: "\(Int(dataMax))",
            insideRect: CGRect(x: graphFrame.origin.x - 30,
                               y: graphFrame.origin.y - (21.0 / 2.0),
                               width: 21.0, height: 21.0),
            onAxis: "y"))
        axisLabels.append(createLabel(fromString: "\(Int((dataMax - dataMin) / 2.0))",
            insideRect: CGRect(x: graphFrame.origin.x - 30,
                               y: graphFrame.origin.y + (graphHeight / 2.0) - (21.0 / 2.0),
                               width: 21.0, height: 21.0),
            onAxis: "y"))
        axisLabels.append(createLabel(fromString: "\(Int(dataMin))",
            insideRect: CGRect(x: graphFrame.origin.x - 30,
                               y: graphFrame.origin.y + graphHeight - (21.0 / 2.0),
                               width: 21.0, height: 21.0),
            onAxis: "y"))
    }
    
    func generateAxisXLabels() {
        let xInterval = (graphWidth) / CGFloat(dataToGraph.count + 1)
        for eachPoint in dataToGraph.indices {
            let xCoordinate = graphFrame.origin.x + (xInterval * CGFloat(eachPoint + 1) - 4.0)
            let yCoordinate = graphFrame.origin.y + (graphHeight * 1.17)
            axisLabels.append(createLabel(fromString: xAxisLabels[eachPoint],
                        insideRect: CGRect(x: xCoordinate, y: yCoordinate, width: 12.0, height: 21.0),
                        onAxis: "x"))
        }
    }
    
    // Animation functions
    
    func animateDataPoints(withDuration duration: TimeInterval) {
        for eachCircleIndex in dataCircles.indices {
            let circle = dataCircles[eachCircleIndex]
            let startPath = circle.path
            let endPath = dataCirclesFinalPaths[eachCircleIndex]
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = startPath
            animation.toValue = endPath
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            circle.add(animation, forKey: "path")
            circle.path = endPath
        }
    }
    
    func animateDataLines(withDuration duration: TimeInterval) {
        for eachLineIndex in dataConnectingLines.indices {
            let line = dataConnectingLines[eachLineIndex]
            let startPath = line.path
            let endPath = dataConnectingLinesFinalPaths[eachLineIndex]
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = startPath
            animation.toValue = endPath
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            line.add(animation, forKey: "path")
            line.path = endPath
        }
    }
    
    // Deletion function
    
    func clearGraph() {
        for eachLine in axisLines {
            eachLine.removeFromSuperlayer()
        }
        for eachLabel in axisLabels {
            eachLabel.removeFromSuperview()
        }
        for eachCircle in dataCircles {
            eachCircle.removeFromSuperlayer()
        }
        for eachLine in dataConnectingLines {
            eachLine.removeFromSuperlayer()
        }
        finalDataCoordinates = [CGPoint]()
        startingDataCoordinates = [CGPoint]()
        dataCircles = [CAShapeLayer]()
        dataCirclesFinalPaths = [CGPath]()
        dataConnectingLines = [CAShapeLayer]()
        dataConnectingLinesFinalPaths = [CGPath]()
        axisLines = [CAShapeLayer]()
        axisLabels = [UILabel]()
    }
}
