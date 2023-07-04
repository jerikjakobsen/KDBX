//
//  File.swift
//  
//
//  Created by John Jakobsen on 5/18/23.
//

import Foundation

class CustomDateFormatter: DateFormatter {
    override init() {
        super.init()
        dateFormat = "E MMM d HH:mm:ss yyyy z"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
