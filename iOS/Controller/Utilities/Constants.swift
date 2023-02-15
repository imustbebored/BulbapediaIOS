//
//  Constants.swift
//  iOS
//
//  Created by Big Sur on 21/01/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Foundation

struct ConstantsKeys {
    
    static let InitialGDPRTexts = "This app personalizes your advertising experience using Playwire and Google Ad Manager. These companies and services, along with Google Firebase, may collect and process personal info such as device IDs, location data, and other interest data to provide ads tailored to you and helpful analytics data for us. We also use local storage to save articles and preferences to your device. By agreeing, you confirm that you are over the age of 16 and accept these terms."
    static let ReviewDialogText = "Thank you so much for using The Bulbapedia App. If you're enjoying it so far, please take a second and leave us a rating. Every single review helps A LOT and is greatly appreciated. A ton of work has gone into this app and we want to thank you all for your support!"
    
}

struct UserDefaultKeys {
    
    static let UD_IsPurchased = "IN_APP_PURCHASE_ADVT"
    static let UD_HandleBannerAdsAppearance = "Handle_Banner_ads"
    static let UD_UpdateMoreButtonWithIAP = "Update_More_Button_WithIAP"
    static let UD_HideBannerOnPurchase = "Hide_Banner_Purchase"
    static let UD_HasLaunchedOnce = "HasLaunchedOnce"
    static let UD_HasTriedRestoredinnewapp = "Has_Tried_Restored_in_new_app"
    static let UD_DismissRemoveAdsScreen = "dismissRemoveAds"
    static let UD_NumberOfAppOpened = "Number_App_Opened"
    static let UD_HasReviewDialogShownOnce = "Has_Review_Dialog_Shown_Once"
    static let UD_MainArticleURL = "Main_Article_URL"
    static let UD_IsNewVersionUpdatedAlready = "UD_IsNesdwVer12s12ionUpd1ateeded123Already"
}
