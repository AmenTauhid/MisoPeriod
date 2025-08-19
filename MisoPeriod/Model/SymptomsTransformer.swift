//
//  SymptomsTransformer.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-19.
//

import Foundation

@objc(SymptomsTransformer)
class SymptomsTransformer: NSSecureUnarchiveFromDataTransformer {
    
    override class var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, NSString.self]
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let symptoms = value as? [String] else { return nil }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: symptoms, requiringSecureCoding: true)
            return data
        } catch {
            print("Failed to archive symptoms: \(error)")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        
        do {
            let symptoms = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSString.self], from: data) as? [String]
            return symptoms
        } catch {
            print("Failed to unarchive symptoms: \(error)")
            return nil
        }
    }
    
    /// Register the transformer
    static func register() {
        let transformer = SymptomsTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName("SymptomsTransformer"))
    }
}