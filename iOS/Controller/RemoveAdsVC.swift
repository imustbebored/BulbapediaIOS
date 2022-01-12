//
//  RemoveAdsVC.swift
//  iOS
//
//  Created by Big Sur on 11/01/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import UIKit
import StoreKit

class RemoveAdsVC: UIViewController {

    var productsArray = [SKProduct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IAPHandler.shared.setProductIds(ids: ["org.bulbagarden.alpha.removeads"])
        IAPHandler.shared.fetchAvailableProducts { [weak self] (products) in
            guard let sSelf = self else {
                return
            }
            sSelf.productsArray = products
            print(sSelf.productsArray)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    @IBAction func btnCloseTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btn320Tapped(_ sender: UIButton) {
        
    }
    
    @IBAction func btn450Tapped(_ sender: UIButton) {
        
    }
}
