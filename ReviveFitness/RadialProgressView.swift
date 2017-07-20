
import UIKit

class RadialProgressView: UIView {
    
    let progressCircleLayer: CAShapeLayer!
    let staticCircleLayer: CAShapeLayer!
    
    // Progress circle is drawn on top of lighter colored static circle
    var progressStroke: UIColor = .black
    var progressFill: UIColor = .clear
    var staticStroke: UIColor = UIColor.init(white: 0.9, alpha: 1.0) // Very light grey
    var staticFill: UIColor = .clear
    
    // Circle line thickness
    var lineWidth: CGFloat = 1.0
    
    // Between 0 and 1, denotes how much of circle is filled
    var progress: CGFloat = 0.0
    
    override init(frame: CGRect) {
        staticCircleLayer = CAShapeLayer()
        progressCircleLayer = CAShapeLayer()
        
        super.init(frame: frame)
        
        createCircles()
    }
    
    required init?(coder aDecoder: NSCoder) {
        staticCircleLayer = CAShapeLayer()
        progressCircleLayer = CAShapeLayer()
        
        super.init(coder: aDecoder)
        
        createCircles()
    }
    
    func createCircles() {
        // Create path (includes entire circle)
        // Careful messing with start/end angle and clockwise
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(
                x: frame.size.width / 2.0,
                y: frame.size.height / 2.0),
            radius: (frame.size.width - 10)/2,
            startAngle: CGFloat(Double.pi * -0.5),
            endAngle: CGFloat(Double.pi * -2.5),
            clockwise: false)
        
        // Set up staticCircleLayer with the path, color, and line width
        staticCircleLayer.path = circlePath.cgPath
        staticCircleLayer.fillColor = staticFill.cgColor
        staticCircleLayer.strokeColor = staticStroke.cgColor
        staticCircleLayer.lineWidth = lineWidth
        
        // Set up progressCircleLayer with the path, color, and line width
        progressCircleLayer.path = circlePath.cgPath
        progressCircleLayer.fillColor = progressFill.cgColor
        progressCircleLayer.strokeColor = progressStroke.cgColor
        progressCircleLayer.lineWidth = lineWidth
        
        // Initially draw the static portion of the circle
        staticCircleLayer.strokeEnd = 1.0
        
        // Initially draw current progress
        progressCircleLayer.strokeEnd = progress
        
        // Add progressCircleLayer and staticCircleLayer to the view's CoreAnimations layer
        layer.addSublayer(staticCircleLayer)
        layer.addSublayer(progressCircleLayer)
    }
    
    func setValueAnimated(duration: TimeInterval, newProgressValue: CGFloat) {
        // Animate the strokeEnd property of the progressCircleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        
        // From start value to end value (0 to 1)
        animation.fromValue = progress
        animation.toValue = newProgressValue
        
        // Uncomment your preferred animation style ->
        //animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        //animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        //animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        // Ensures strokeEnd property is the right value when animation ends
        progressCircleLayer.strokeEnd = newProgressValue
        self.progress = newProgressValue
        
        // Add the animation
        progressCircleLayer.add(animation, forKey: "animateCircle")
    }
    
}
