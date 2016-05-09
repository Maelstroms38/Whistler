//
//  Whistle.swift
//  Whistler
//
//  Created by Michael Stromer on 5/3/16.
//  Copyright © 2016 Michael Stromer. All rights reserved.
//

import UIKit
import CloudKit

class Whistle: NSObject {
    var recordID: CKRecordID!
    var genre: String!
    var comments: String!
    var audio: NSURL!
}
