//
//  LoadingScreen.swift
//  test
//
//  Created by Jessica Zhang on 5/2/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit

class LoadingScreen: UIVisualEffectView {
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let label = UILabel()
    var text = ""
    let blur = UIBlurEffect(style: .light)
    let view: UIVisualEffectView
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    init(_ text: String) {
        view = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blur))
        self.text = text
        super.init(effect: blur)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.text = ""
        view = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blur))
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        contentView.addSubview(view)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(label)
        activityIndicator.startAnimating()
    }
    
    func show() {
        self.isHidden = false
    }
    
    func hide() {
        self.isHidden = true
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let superview = self.superview {
            
            let width = superview.frame.size.width / 2.3
            let height: CGFloat = 50.0
            self.frame = CGRect(x: superview.frame.size.width / 2 - width / 2,
                                y: superview.frame.height / 2 - height / 2,
                                width: width,
                                height: height)
            view.frame = self.bounds
            
            let activityIndicatorSize: CGFloat = 40
            activityIndicator.frame = CGRect(x: 5,
                                             y: height / 2 - activityIndicatorSize / 2,
                                             width: activityIndicatorSize,
                                             height: activityIndicatorSize)
            
            layer.cornerRadius = 8.0
            layer.masksToBounds = true
            label.text = text
            label.textAlignment = NSTextAlignment.center
            label.frame = CGRect(x: activityIndicatorSize + 5,
                                y: 0,
                                width: width - activityIndicatorSize - 15,
                                height: height)
            label.textColor = UIColor.systemGray4
            label.font = UIFont.boldSystemFont(ofSize: 16)
        }
    }
    
    deinit {
        print("Load Screen deinitialized")
    }
}
