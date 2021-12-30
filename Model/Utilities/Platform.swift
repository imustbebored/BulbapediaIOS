//
//  Platform.swift
//  Kiwix
//
//  Created by Chris Li on 5/10/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias NSUIFont = UIFont
public typealias NSUIImage = UIImage
#endif

#if os(OSX)
import Cocoa

public typealias NSUIFont = NSFont
public typealias NSUIImage = NSImage
#endif
