//
//  FSTracking.swift
//  FlagShip
//
//  Created by Adel on 13/08/2019.
//

import Foundation

 /// :nodoc:
@objc public enum FSTypeTrack: NSInteger {

    case SCREEN        = 0
    case TRANSACTION
    case ITEM
    case EVENT
    case None

    public var typeString: String {

        switch self {
        case .SCREEN:
            return "SCREENVIEW"
        case .TRANSACTION:
            return "TRANSACTION"
        case .ITEM:
            return "ITEM"
        case .EVENT:
            return "EVENT"
        case .None:
            return "None"
        }
    }
}

/// Enumeration that represent Events type
 @objc public enum FSCategoryEvent: NSInteger {

    /// Action tracking
    case Action_Tracking     = 1

    /// User engagement
    case User_Engagement     = 2

    /// :nodoc:
    public var categoryString: String {

        switch self {
        case .Action_Tracking:
            return "Action Tracking"
        case .User_Engagement:
            return "User Engagement"
        }
    }
}

/// :nodoc:
@objc public protocol FSTrackingProtocol {

    var type: FSTypeTrack { get }

    var bodyTrack: [String: Any] { get }

    var fileName: String! { get }

    /// Get cst
    func getCst() -> NSNumber?

}

/// :nodoc:
@objcMembers public class FSTracking: NSObject, FSTrackingProtocol {

    public func getCst() -> NSNumber? {

        return NSNumber(floatLiteral: self.currentSessionTimeStamp ?? 0)
    }

    public var fileName: String! {

        get {

            let formatDate = DateFormatter()
            formatDate.dateFormat = "MMddyyyyHHmmssSSSS"
            return String(format: "%@.json", formatDate.string(from: Date()))
        }
    }

    // Here will add all commun args
    public var type: FSTypeTrack = .None

    // Required
    var clientId: String?
    var fsUserId: String?
    var visitorId: String?
    var dataSource: String = "APP"

    /// InterfaceName
    /// This attribute in no longer used in hits, use the location instead in screen hit
    // public var interfaceName:String?

    var anonymousId: String?

    /// User Ip
    public var userIp: String?
    /// Screen Resolution
    public var screenResolution: String?
    /// Screen Color Depth
    public var screenColorDepth: String?
    /// User Language
    public var userLanguage: String?
    /// Queue Time
    public var queueTime: Int64?
    /// Current Session Time Stamp
    public var currentSessionTimeStamp: TimeInterval?
    /// Session Number
    public var sessionNumber: NSNumber?

    // Session Event Number
    public var sessionEventNumber: NSNumber?

    override init() {

        clientId        = Flagship.sharedInstance.environmentId
        visitorId       = Flagship.sharedInstance.visitorId
        anonymousId     = Flagship.sharedInstance.anonymousId

        // Set time Stamps
        self.currentSessionTimeStamp = Date.timeIntervalSinceReferenceDate
    }

    public var bodyTrack: [String: Any] {

        get {

            return [:]
        }
    }

    public var communBodyTrack: [String: Any] {

        get {

             var communParams: [String: Any] = [String: Any]()
            // Set Client Id
            communParams.updateValue(self.clientId ?? "", forKey: "cid") //// Rename it
            // Set FlagShip user id Id

            // communParams.updateValue(self.visitorId ?? "", forKey: "vid")  //// rename it
            communParams.merge(createTupleId()) {  (_, new) in new }
            // Set Data source
            communParams.updateValue(self.dataSource, forKey: "ds")
            // Set User ip
            if self.userIp != nil {
                communParams.updateValue(self.userIp ?? "", forKey: "uip")
            }
            // Set Resolution Screen
            if self.screenResolution != nil {
                communParams.updateValue(self.screenResolution ?? "", forKey: "sr")
            }
            // Set  Screen Color Depth
            if self.screenColorDepth != nil {
                communParams.updateValue(self.screenColorDepth ?? "", forKey: "sd")
            }
            // User Language
            if self.userLanguage != nil {
                communParams.updateValue(self.userLanguage ?? "", forKey: "ul")
            }

            // Session Number
            if self.sessionNumber != nil {
                communParams.updateValue(self.sessionNumber ?? 0, forKey: "sn")
            }

            return communParams
        }
    }

    private func createTupleId() -> [String: Any] {

        var tupleId: [String: Any] = [String: Any]()

        if self.anonymousId != nil && self.visitorId != nil {

            // envoyer: cuid = visitorId, et vid=anonymousId

            tupleId.updateValue(self.visitorId ?? "", forKey: "cuid")  //// rename it

            tupleId.updateValue(self.anonymousId ?? "", forKey: "vid")  //// rename it

        } else if self.visitorId != nil {

            // Si visitorid défini mais pas anonymousId, cuid pas envoyé, vid = visitorId
            tupleId.updateValue(self.visitorId ?? "", forKey: "vid")  //// rename it

        } else {

            /// Error case
        }
        return tupleId
    }
}
