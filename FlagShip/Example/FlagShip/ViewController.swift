//
//  ViewController.swift
//  FlagShip
//
//  Created by Adel on 08/08/2019.
//  Copyright (c) 2019 Adel. All rights reserved.
//

import UIKit
import FlagShip

class ViewController: UIViewController {
    
    @IBOutlet var mainTitle:UILabel!
    
   // @IBOutlet var newFeature:UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.mainTitle.text = ABFlagShip.sharedInstance.shipStringeValue("titleBtn", defaultString: "None")
        
      //  self.newFeature.isHidden = ABFlagShip.sharedInstance.shipBooleanValue("isVip", defaultBool: true)
    }
    
    
    
    
    
    @IBAction func back(){
        
        self.dismiss(animated: true) {
        }
    }


    @IBAction func sendAction(){
        
        let eventAction = FSEventTrack(.Action_Tracking, "iosAction", "iosLabel", 3.14)
        ABFlagShip.sharedInstance.sendTracking(eventAction)
        
    }



}

