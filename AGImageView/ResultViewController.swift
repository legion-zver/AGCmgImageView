//
//  ResultViewController.swift
//  AGImageView
//
//  Created by Александр Зверь on 17.11.16.
//  Copyright © 2016 ALEXANDER GARIN. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    
    public var image:UIImage? = nil
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.imageView.image = self.image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
