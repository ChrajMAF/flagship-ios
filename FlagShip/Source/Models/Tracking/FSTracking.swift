//
//  FSTracking.swift
//  Flagship
//
//  Created by Adel on 11/10/2021.
//

import Foundation

@objc public enum FSTypeTrack: NSInteger {
    case SCREEN = 0
    case TRANSACTION
    case ITEM
    case EVENT
    case CONSENT
    case BATCH
    case ACTIVATE
    case None

    public var typeString: String {
        switch self {
        case .SCREEN:
            return "SCREENVIEW"
        case .TRANSACTION:
            return "TRANSACTION"
        case .ITEM:
            return "ITEM"
        case .EVENT, .CONSENT:
            return "EVENT"
        case .BATCH:
            return "BATCH"
        case .ACTIVATE:
            return "ACTIVATE"
        case .None:
            return "None"
        }
    }
}

/// Enumeration that represent Events type
@objc public enum FSCategoryEvent: NSInteger {
    /// Action tracking
    case Action_Tracking = 1

    /// User engagement
    case User_Engagement = 2

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
    var id: String { get set }

    var anonymousId: String? { get set }

    var visitorId: String? { get set }

    var type: FSTypeTrack { get }

    var bodyTrack: [String: Any] { get }

    var fileName: String! { get }

    /// Required
    var envId: String? { get }

    /// Queue Time
    var queueTimeBis: NSNumber? { get }

    /// Get cst
    func getCst() -> NSNumber?

    func isValid() -> Bool
}

@objcMembers public class FSTracking: NSObject, FSTrackingProtocol {
    public var queueTimeBis: NSNumber?

    public var visitorId: String?

    public var id: String

    // Anonymous ID
    public var anonymousId: String?

    // public var visitorId: String?

    public func getCst() -> NSNumber? {
        return NSNumber(floatLiteral: self.currentSessionTimeStamp ?? 0)
    }

    public var fileName: String! {
        let formatDate = DateFormatter()
        formatDate.dateFormat = "MMddyyyyHHmmssSSSS"
        return String(format: "%@.json", formatDate.string(from: Date()))
    }

    // Here will add all commun args
    public var type: FSTypeTrack = .None

    /// Required
    public var envId: String?
    var fsUserId: String?
    // var visitorId: String?
    var dataSource: String = "APP"

    /// User Ip
    public var userIp: String?
    /// Screen Resolution
    public var screenResolution: String?
    /// Screen Color Depth
    public var screenColorDepth: String?
    /// User Language
    public var userLanguage: String?
    /// Queue Time
    // public var queueTime: Int64?
    /// Current Session Time Stamp
    public var currentSessionTimeStamp: TimeInterval?
    /// Session Number
    public var sessionNumber: NSNumber?

    // Session Event Number
    public var sessionEventNumber: NSNumber?

    // Created time
    public var createdAt: TimeInterval??

    override init() {
        self.id = ""
        self.envId = Flagship.sharedInstance.envId
        // Set TimeInterval
        self.currentSessionTimeStamp = Date.timeIntervalSinceReferenceDate
        // Created date
        self.createdAt = Date.timeIntervalSinceReferenceDate
    }

    public var bodyTrack: [String: Any] {
        return [:]
    }

    public var communBodyTrack: [String: Any] {
        var communParams = [String: Any]()
        // Set Client Id
        // communParams.updateValue(self.envId ?? "", forKey: "cid") //// Rename it
        // Set FlagShip user id Id
        // Set Data source
        // communParams.updateValue(self.dataSource, forKey: "ds")
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
        // Merge the visitorId and AnonymousId
        communParams.merge(self.createTupleId()) { _, new in new }

        /// Add qt entries
        /// Time difference between when the hit was created and when it was sent
        ///
        if let aCreatedTime = self.createdAt {
            let duration = aCreatedTime?.distance(to: Date.timeIntervalSinceReferenceDate)
            communParams.updateValue(duration ?? 0, forKey: "qt")
        }

        return communParams
    }

    public func isValid() -> Bool {
        if let aVisitorId = self.visitorId, let aClientId = self.envId {
            return (!aVisitorId.isEmpty && !aClientId.isEmpty && self.type != .None)
        }

        return false
    }

    internal func createTupleId() -> [String: String] {
        var tupleId = [String: String]()

        if self.anonymousId != nil /* && self.visitorId != nil */ {
            // envoyer: cuid = visitorId, et vid=anonymousId
            tupleId.updateValue(self.visitorId ?? "", forKey: "cuid") //// rename it
            tupleId.updateValue(self.anonymousId ?? "", forKey: "vid") //// rename it
        } else /* if self.visitorId != nil*/ {
            // Si visitorid défini mais pas anonymousId, cuid pas envoyé, vid = visitorId
            tupleId.updateValue(self.visitorId ?? "", forKey: "vid") //// rename it
        }
        return tupleId
    }
}
