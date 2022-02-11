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
    
    @IBOutlet weak var btnPrice: UIButton!
    
    var productsArray = [SKProduct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnPrice.isUserInteractionEnabled = false
        IAPHandler.shared.setProductIds(ids: ["org.bulbagarden.alpha.removeads"])
        IAPHandler.shared.fetchAvailableProducts { [weak self] (products) in
            guard let sSelf = self else {
                return
            }
            sSelf.productsArray = products
            DispatchQueue.main.async {
                sSelf.btnPrice.setTitle("\(sSelf.productsArray[0].price) ONE TIME", for: .normal)
                sSelf.btnPrice.isUserInteractionEnabled = true
            }
            print(sSelf.productsArray)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(dismissSelf), name: NSNotification.Name(UserDefaultKeys.UD_DismissRemoveAdsScreen), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func btnCloseTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnPricePurchaseTapped(_ sender: UIButton) {
        if self.productsArray.count == 0 {return}
        IAPHandler.shared.purchase(product: self.productsArray[0]) { alert, product, transaction in
            if let tran = transaction, let prod = product {
                print(tran.payment.productIdentifier)
                self.dismiss(animated: true, completion: nil)
                print("Purchased product:- \(prod.localizedTitle)")
            }
        }
    }
}
