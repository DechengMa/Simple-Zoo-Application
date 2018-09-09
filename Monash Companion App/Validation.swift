//
//  Validation.swift
//  Monash Companion App
//
//  Created by Decheng Ma on 30/8/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
//Seldom used, only used it in input name and description https://medium.com/@sandshell811/generic-way-to-validate-textfield-inputs-in-swift-3-cc031b1e651e
class Validation: NSObject {
    
    public static let shared = Validation()
    
    func validate(values: (type: ValidationType, inputValue: String)...) -> Valid {
        for valueToBeChecked in values {
            switch valueToBeChecked.type {
            case .stringWithFirstLetterCaps:
                if let tempValue = isValidString((valueToBeChecked.inputValue, .alphabeticStringFirstLetterCaps, .emptyFirstLetterCaps, .invalidFirstLetterCaps)) {
                    return tempValue
                }
            case .alphabeticString:
                if let tempValue = isValidString((valueToBeChecked.inputValue, .alphabeticStringWithSpace, .emptyAlphabeticString, .invalidAlphabeticString)) {
                    return tempValue
                }
            }
        }
        return .success
    }
    
    
    func isValidString(_ input: (text: String, regex: RegEx, emptyAlert: AlertMessages, invalidAlert: AlertMessages)) -> Valid? {
        if input.text.isEmpty {
            return .failure(.error, input.emptyAlert)
        } else if isValidRegEx(input.text, input.regex) != true {
            return .failure(.error, input.invalidAlert)
        }
        return nil
    }
    
    func isValidRegEx(_ testStr: String, _ regex: RegEx) -> Bool {
        let stringTest = NSPredicate(format:"SELF MATCHES %@", regex.rawValue)
        let result = stringTest.evaluate(with: testStr)
        return result
    }
    
    enum Alert {        //for failure and success results
        case success
        case failure
        case error
    }
    //for success or failure of validation with alert message
    enum Valid {
        case success
        case failure(Alert, AlertMessages)
    }
    enum ValidationType {
        case stringWithFirstLetterCaps
        case alphabeticString
    }
    enum RegEx: String {
        case alphabeticStringWithSpace = "^[a-zA-Z ]*$" // e.g. hello sandeep
        case alphabeticStringFirstLetterCaps = "^[A-Z]+[a-zA-Z]*$" // SandsHell
    }
    
    enum AlertMessages: String {
        case invalidFirstLetterCaps = "First Letter of Name should be capitalize with no space"
        case invalidAlphabeticString = "Invalid Description!"
        
        case emptyFirstLetterCaps = "Sorry Name can not be empty!"
        case emptyAlphabeticString = "Sorry Description can not be empty!"
        
        func localized() -> String {
            return NSLocalizedString(self.rawValue, comment: "")
        }
    }
}

