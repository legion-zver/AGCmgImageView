//
//  ViewController.swift
//  AGImageView
//
//  Created by Александр Зверь on 16.11.16.
//  Copyright © 2016 ALEXANDER GARIN. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: AGCmgImageView!
    
    private var resultImage: UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = UIImage(named: "ExampleImage2")        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func didChangeRotateZ(_ sender: UISlider) {
        imageView.angleZ = CGFloat(sender.value)
    }
    @IBAction func didChangeRotateY(_ sender: UISlider) {
        imageView.angleY = CGFloat(sender.value)
    }
    @IBAction func didChangeRotateX(_ sender: UISlider) {
        imageView.angleX = CGFloat(sender.value)
    }
    @IBAction func didCangeBr(_ sender: UISlider) {
        imageView.brightness = CGFloat(sender.value)
    }
    @IBAction func didChangeS(_ sender: UISlider) {
        imageView.saturation = CGFloat(sender.value)
    }
    @IBAction func didChangeC(_ sender: UISlider) {
        imageView.contrast = CGFloat(sender.value)
    }
    @IBAction func didChangeG(_ sender: UISlider) {
        imageView.gamma = CGFloat(sender.value)
    }
    @IBAction func didChangePreview(_ sender: UISwitch) {
        imageView.usePreview = sender.isOn
    }
    @IBAction func didChangeCropping(_ sender: UISwitch) {
        imageView.isCropping = sender.isOn
    }
    
    @IBAction func clickDone(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        // Генерируем результат 
        self.imageView.createResultImage { (image: UIImage?) in
            if image != nil {
                self.resultImage = image
                self.performSegue(withIdentifier: "ShowResult", sender: self)
            }
            sender.isEnabled = true
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != nil {
            if let vc = segue.destination as? ResultViewController, segue.identifier == "ShowResult" {
                vc.image = self.resultImage
            }
        }
        self.resultImage = nil
    }
}

