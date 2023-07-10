//
//  FSTargetingManager.swift
//  FlagShip-framework
//
//  Created by Adel on 21/11/2019.
//

import Foundation

/// :nodoc:
let FS_USERS = "fs_users"

/// :nodoc:
enum FStargetError: Error {
    case unknownType
}

/// :nodoc:
internal enum FSoperator: String, CaseIterable {
    case EQUALS
    case NOT_EQUALS
    case GREATER_THAN
    case GREATER_THAN_OR_EQUALS
    case LOWER_THAN
    case LOWER_THAN_OR_EQUALS
    case CONTAINS
    case NOT_CONTAINS
    case SEMVER_EQUALS
    case SEMVER_NOT_EQUALS
    case SEMVER_GREATER_THAN
    case SEMVER_LOWER_THAN
    case SEMVER_GREATER_THAN_OR_EQUALS
    case SEMVER_LOWER_THAN_OR_EQUALS

    case Unknown
}

/// :nodoc:
class FSTargetingManager {
    var userId: String = ""
    var currentContext: [String: Any] = [:]

    // Entre chanque groupe on fait OR
    // Entre chaque item on fait AND

    internal func isTargetingGroupIsOkay(_ targeting: FSTargeting?) -> Bool {
        if targeting == nil {
            return false
        }

        // The actual context app
        // will check if the key/value in target are the same with the context, to match audience
        // let currentContext:Dictionary <String, Any> = ABFlagShip.sharedInstance.context!.currentContext

        // Groupe de variations
        var booleanResultGroup: [Bool] = []

        if let arrayTargetingGroup = targeting?.targetingGroups {
            for targetingGroup: FSTargetingGroup in arrayTargetingGroup {
                booleanResultGroup.append(checkTargetGroupIsOkay(targetingGroup))
            }
        }

        // Here we supposed to have all result , we should have at least one true value to return YES, because we have -OR- between Groups
        return booleanResultGroup.contains(true)
    }

    //// Check target for lists

    internal func checkTargetingForList(currentValue: Any?, opType: FSoperator, listAudience: Any?) -> Bool {
        /// Chekc the type list before
        var isOkay = false
        var result = 0
        if let values = listAudience as? [Any] {
            for subAudienceValue in values {
                isOkay = checkCondition(currentValue as Any, opType, subAudienceValue as Any)
                /// For those operator, we use  --- OR ---
                if opType == .CONTAINS || opType == .EQUALS || opType == .SEMVER_EQUALS {
                    if isOkay {
                        /// At least one condition in the liste is valide ==> return true.
                        return true
                    } else {
                        /// Set result == 1 to return false, in case when all condition on the liste are not valide
                        result = 1
                    }
                    /// For those operator, we use  --- AND ---
                } else if opType == .NOT_EQUALS || opType == .NOT_CONTAINS || opType == .SEMVER_NOT_EQUALS {
                    result += isOkay ? 0 : 1
                } else {
                    /// return false for others operator
                    return false
                }
            }
            return (result == 0)
        }
        return false
    }

    internal func checkTargetGroupIsOkay(_ itemTargetGroup: FSTargetingGroup) -> Bool {
        // let currentContext:Dictionary <String, Any> = ABFlagShip.sharedInstance.context!.currentContext

        for itemTarget in itemTargetGroup.targetings {
            // Cuurent context value
            // let currentContextValue = currentContext[itemTarget.tragetKey]

            let currentContextValue = getCurrentValueFromCtx(itemTarget.tragetKey)

            // Audience value
            let audienceValue = itemTarget.targetValue
            // Create the type operator
            let opType: FSoperator = .init(rawValue: itemTarget.targetOperator) ?? .Unknown

            /// Special treatment for array
            var isOkay: Bool = false

            if audienceValue is [String] || audienceValue is [Int] || audienceValue is [Double] {
                isOkay = checkTargetingForList(currentValue: currentContextValue, opType: opType, listAudience: audienceValue)

            } else {
                isOkay = checkCondition(currentContextValue as Any, opType, audienceValue as Any)
            }

            if !isOkay {
                return false
            }
        }
        return true
    }

    func checkCondition(_ currentValue: Any, _ operation: FSoperator, _ audienceValue: Any) -> Bool {
        switch operation {
        case .EQUALS:

            do {
                return try IsCurrentValueEqualToAudienceValue(currentValue, audienceValue)

            } catch {
                return false
            }

        case .NOT_EQUALS:

            do {
                return try !IsCurrentValueEqualToAudienceValue(currentValue, audienceValue)

            } catch {
                return false
            }

        case .GREATER_THAN:

            do {
                return try isCurrentValueIsGreaterThanAudience(currentValue, audienceValue)

            } catch {
                return false
            }

        case .GREATER_THAN_OR_EQUALS:

            do {
                return try isCurrentValueIsGreaterThanOrEqualAudience(currentValue, audienceValue)

            } catch {
                return false
            }

        case .LOWER_THAN:

            do {
                return try isCurrentValueIsLowerThanAudience(currentValue, audienceValue)

            } catch {
                return false
            }

        case .LOWER_THAN_OR_EQUALS:

            do {
                return try isCurrentValueIsLowerThanOrEqualAudience(currentValue, audienceValue)

            } catch {
                return false
            }

        case .CONTAINS:

            do {
                return try isCurrentValueContainAudience(currentValue, audienceValue)

            } catch {
                return false
            }

        case .NOT_CONTAINS:

            do {
                return try !isCurrentValueContainAudience(currentValue, audienceValue)

            } catch {
                return false
            }

        case .SEMVER_EQUALS,
             .SEMVER_NOT_EQUALS,
             .SEMVER_LOWER_THAN,
             .SEMVER_GREATER_THAN,
             .SEMVER_LOWER_THAN_OR_EQUALS,
             .SEMVER_GREATER_THAN_OR_EQUALS:
            // Check if the values are strings
            if let a = currentValue as? String, let b = audienceValue as? String {
                return checkSemver(operation, a, b)
            } else {
                FlagshipLogManager.Log(level: .ALL, tag: .TARGETING, messageToDisplay: FSLogMessage.MESSAGE("Bad format for the semantic version, the value should be String ===> The semantic \(operation) condition is not satisfied ❌"))
                return false
            }

        default:
            return false
        }
    }

    /// Compare EQUALS

    internal func IsCurrentValueEqualToAudienceValue(_ currentValue: Any, _ audienceValue: Any) throws -> Bool {
        var ret = false

        if currentValue is Int {
            ret = isEqual(type: Int.self, a: currentValue, b: audienceValue)

        } else if currentValue is String {
            ret = isEqual(type: String.self, a: currentValue, b: audienceValue)

        } else if currentValue is Bool {
            ret = isEqual(type: Bool.self, a: currentValue, b: audienceValue)

        } else if currentValue is Double {
            ret = isEqual(type: Double.self, a: currentValue, b: audienceValue)

        } else {
            throw FStargetError.unknownType
        }

        return ret
    }

    /// Compare greater than

    internal func isCurrentValueIsGreaterThanAudience(_ currentValue: Any, _ audienceValue: Any) throws -> Bool {
        var ret = false

        if currentValue is Int {
            ret = isGreatherThan(type: Int.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is String {
            ret = isGreatherThan(type: String.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is Double {
            ret = isGreatherThan(type: Double.self, a: currentValue, b: audienceValue)
            return ret
        } else {
            throw FStargetError.unknownType
        }
    }

    /// Compare greater than or equal
    internal func isCurrentValueIsGreaterThanOrEqualAudience(_ currentValue: Any, _ audienceValue: Any) throws -> Bool {
        var ret = false

        if currentValue is Int {
            ret = isGreatherThanorEqual(type: Int.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is String {
            ret = isGreatherThanorEqual(type: String.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is Double {
            ret = isGreatherThanorEqual(type: Double.self, a: currentValue, b: audienceValue)
            return ret
        } else {
            throw FStargetError.unknownType
        }
    }

    /// Compare lower than

    internal func isCurrentValueIsLowerThanAudience(_ currentValue: Any, _ audienceValue: Any) throws -> Bool {
        var ret = false

        if currentValue is Int {
            ret = isLowerThan(type: Int.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is String {
            ret = isLowerThan(type: String.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is Double {
            ret = isLowerThan(type: Double.self, a: currentValue, b: audienceValue)
            return ret
        } else {
            throw FStargetError.unknownType
        }
    }

    /// Compare lower than or equal
    internal func isCurrentValueIsLowerThanOrEqualAudience(_ currentValue: Any, _ audienceValue: Any) throws -> Bool {
        var ret = false

        if currentValue is Int {
            ret = isLowerThanorEqual(type: Int.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is String {
            ret = isLowerThanorEqual(type: String.self, a: currentValue, b: audienceValue)
            return ret
        } else if currentValue is Double {
            ret = isLowerThanorEqual(type: Double.self, a: currentValue, b: audienceValue)
            return ret
        } else {
            throw FStargetError.unknownType
        }
    }

    /// Compare contain
    internal func isCurrentValueContainAudience(_ currentValue: Any, _ audienceValue: Any) throws -> Bool {
        if currentValue is String && audienceValue is String {
            guard let currentValue = currentValue as? String, let audienceValue = audienceValue as? String else { throw FStargetError.unknownType }

            return currentValue.contains(audienceValue)
        } else {
            throw FStargetError.unknownType
        }
    }

    ////// Toools ///////
    func isEqual<T: Equatable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }

        return a == b
    }

    func isGreatherThan<T: Comparable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }

        return a > b
    }

    func isGreatherThanorEqual<T: Comparable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }

        return a >= b
    }

    func isLowerThan<T: Comparable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }

        return a < b
    }

    func isLowerThanorEqual<T: Comparable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }

        return a <= b
    }

    internal func getCurrentValueFromCtx(_ targetKey: String) -> Any? {
        if targetKey == FS_USERS {
            return userId
        } else {
            return currentContext[targetKey]
        }
    }
}
