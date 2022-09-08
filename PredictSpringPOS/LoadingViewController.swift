//
//  LoadingViewController.swift
//  PredictSpringPOS
//
//  Created by Avi L on 9/8/22.
//

import UIKit

class LoadingViewController: UIViewController {
    var loadingActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        
        indicator.style = .large
        indicator.color = .white
            
        // The indicator should be animating when
        // the view appears.
        indicator.startAnimating()
            
        // Setting the autoresizing mask to flexible for all
        // directions will keep the indicator in the center
        // of the view and properly handle rotation.
        indicator.autoresizingMask = [
            .flexibleLeftMargin, .flexibleRightMargin,
            .flexibleTopMargin, .flexibleBottomMargin
        ]
            
        return indicator
    }()
    
    var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        blurEffectView.alpha = 0.8
        
        // Setting the autoresizing mask to flexible for
        // width and height will ensure the blurEffectView
        // is the same size as its parent view.
        blurEffectView.autoresizingMask = [
            .flexibleWidth, .flexibleHeight
        ]
        
        return blurEffectView
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Add the blurEffectView with the same
        // size as view
        blurEffectView.frame = self.view.bounds
        view.insertSubview(blurEffectView, at: 0)
        
        // Add the loadingActivityIndicator in the
        // center of view
        loadingActivityIndicator.center = CGPoint(
            x: view.bounds.midX,
            y: view.bounds.midY
        )
        view.addSubview(loadingActivityIndicator)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
