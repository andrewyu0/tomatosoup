//
//  DetailViewController.swift
//  tomatosoup
//
//  Created by Andrew Yu on 2/2/16.
//  Copyright © 2016 Andrew Yu. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var posterImageView : UIImageView!
    @IBOutlet weak var titleLabel      : UILabel!
    @IBOutlet weak var overviewLabel   : UILabel!
    @IBOutlet weak var scrollView      : UIScrollView!
    @IBOutlet weak var infoView        : UIView!
    
    var movie            : NSDictionary!
    var placeHolderImage : UIImage?
    var imageUrl         : NSURL!
    
    override func viewDidAppear(animated: Bool) {
        
        UIView.animateWithDuration(0.5,
            delay: 0,
            options: .CurveEaseInOut ,
            animations: {
                self.infoView.frame = CGRectMake(0, 300, 400, 400)
            },
            completion: { finished in
                print("animation completed")
            })
    }
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)
        
        let title    = movie["title"] as! String
        let overview = movie["overview"] as! String

        // Get image url and set to posterImageView 
        
        let baseUrl    = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath)
            posterImageView.setImageWithURL(imageUrl!)
        }
        
        titleLabel.text    = title
        overviewLabel.text = overview
        overviewLabel.sizeToFit()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
