//
//  FSContinuousTrackingManager.swift
//  Flagship
//
//  Created by Adel Ferguen on 27/03/2023.
//  Copyright © 2023 FlagShip. All rights reserved.
//

import Foundation

class ContinuousTrackingManager: FSTrackingManager {
    // Create batch manager
    override init(_ pService: FSService, _ pTrackingConfig: FSTrackingConfig, _ pCacheManager: FSCacheManager) {
        super.init(pService, pTrackingConfig, pCacheManager)

        // Get the remained hit
        cacheManager?.lookupHits(onCompletion: { error, remainedHits in
            if error == nil {
//                remainedHits?.forEach { (_: String, value: [String: Any]) in
//
//                    do {
//                        var cachedHits: [FSTrackingProtocol] = []
//                        let decoder = JSONDecoder()
//                        let jsonData = try JSONSerialization.data(withJSONObject: value)
//
//                        if let type = value["t"] as? String {
//                            switch type {
//                            case "SCREENVIEW":
//                                try cachedHits.append(decoder.decode(FSScreen.self, from: jsonData))
//                            case "EVENT":
//                                try cachedHits.append(decoder.decode(FSEvent.self, from: jsonData))
//                            case "TRANSACTION":
//                                try cachedHits.append(decoder.decode(FSTransaction.self, from: jsonData))
//                            case "ITEM":
//                                try cachedHits.append(decoder.decode(FSItem.self, from: jsonData))
//                            // case "ACTIVATE":
//                            // cachedHit = try decoder.decode(Activate.self, from: jsonData)
//                            default:
//                                print("unknow data")
//                            }
//
//                            if !cachedHits.isEmpty {
//                                self.batchManager.reInjectElementsBis(listToReInject: cachedHits)
//                            }
//
//                        } else {
//                            print("Error on reading type of event")
//                        }
//
//                    } catch {
//                        print("error on looup convert")
//                    }
//                }
                
                if let aRemainedHits = remainedHits{
                    self.batchManager.reInjectElements(listToReInject: aRemainedHits)

                }
            }
        })
    }

    // SEND HIT ---------------------//
    override func sendHit(_ hitToSend: FSTrackingProtocol) {
        if hitToSend.isValid() {
            batchManager.addTrackElement(hitToSend)

            // Save hit in Database
            cacheManager?.cacheHits(hits: [hitToSend.id: hitToSend.bodyTrack])
        } else {
            FlagshipLogManager.Log(level: .ALL, tag: .TRACKING, messageToDisplay: FSLogMessage.MESSAGE("hit not valide to be sent "))
        }
    }

    // SEND ACTIVATE --------------//
    override func sendActivate(_ currentActivate: Activate?) {
        // Create activate batch
        let activateBatch = ActivateBatch(pCurrentActivate: currentActivate)

        // Get the old activate if exisit
        if !batchManager.isQueueEmpty(activatePool: true) {
            activateBatch.addListOfElement(batchManager.extractAllElements(activatePool: true))
        }

        // Send Activate
        service.activate(activateBatch.bodyTrack) { error in
            if error == nil {
                FlagshipLogManager.Log(level: .ALL, tag: .ACTIVATE, messageToDisplay: FSLogMessage.MESSAGE("Activate sent with sucess"))
                self.onSucessToSendActivate(activateBatch)
            } else {
                FlagshipLogManager.Log(level: .ALL, tag: .ACTIVATE, messageToDisplay: FSLogMessage.MESSAGE("Failed to send Activate"))
                self.onFailedToSendActivate(activateBatch)
            }
        }
    }

    override func stopBatchingProcess() {
        batchManager.pauseBatchProcess()
    }

    override func resumeBatchingProcess() {
        batchManager.resumeBatchProcess()
    }

    // ************** BATCH PROCESS ***********//
    override internal func processActivatesBatching() {
        // We pass nil here because will batch the activate pool without a current one
        self.sendActivate(nil)
    }

    override internal func processHitsBatching(batchToSend: FSBatch) {
        do {
            let batchData = try JSONSerialization.data(withJSONObject: batchToSend.bodyTrack as Any, options: .prettyPrinted)

            FlagshipLogManager.Log(level: .ALL, tag: FSTag.TRACKING, messageToDisplay: FSLogMessage.MESSAGE(batchData.prettyPrintedJSONString as String?))

            if let urlEvent = URL(string: EVENT_TRACKING) {
                service.sendRequest(urlEvent, type: .Tracking, data: batchData, onCompleted: { _, error in

                    if error == nil {
                        FlagshipLogManager.Log(level: .INFO, tag: .TRACKING, messageToDisplay: FSLogMessage.SUCCESS_SEND_HIT)
                        self.onSucessToSendHits(batchToSend)
                    } else {
                        self.onFailedToSendHits(batchToSend)
                        FlagshipLogManager.Log(level: .INFO, tag: .TRACKING, messageToDisplay: FSLogMessage.SEND_EVENT_FAILED)
                    }
                })
            }
        } catch {
            FlagshipLogManager.Log(level: .ERROR, tag: .TARGETING, messageToDisplay: FSLogMessage.SEND_EVENT_FAILED)
        }
    }

    
    
    // ********** HITS ************//
    override
    internal func onSucessToSendHits(_ batchToSend: FSBatch) {
        // Create a list of hits id to remove for database
        self.cacheManager?.hitCacheDelegate?.flushHits(hitIds: batchToSend.items.map { elem in
            elem.id
        })
    }

    override
    internal func onFailedToSendHits(_ batchToSend: FSBatch) {
        // Re inject the hits into the pool on failed request
        self.batchManager.reInjectElements(listToReInject: batchToSend.items)
    }

    // ********** ACTIVATE ********//
    override
    internal func onSucessToSendActivate(_ activateBatch: ActivateBatch) {
        // If the activate Pool is not empty ==> clean the pool and database
        if !self.batchManager.isQueueEmpty(activatePool: true) {
            // Create array of ids and use it by the flush database
            self.cacheManager?.flushHits(activateBatch.listActivate.map { elem in
                elem.id
            })

            // Clear all the activate present in the pool
            // TODO: Check it should be gonne already on extracting the first time
            self.batchManager.removeTrackElements(listToRemove: activateBatch.listActivate)
        }
    }

    override
    internal func onFailedToSendActivate(_ activateBatch: ActivateBatch) {
        // Add the current activate to batch
        self.batchManager.reInjectElements(listToReInject: activateBatch.listActivate)

        // Add in cache the current Activate; The current activate is the first on the list activateBatch
        if let currentActivate = activateBatch.currentActivate {
            self.cacheManager?.cacheHits(hits: [currentActivate.id: currentActivate.bodyTrack])
        }
    }

    // Remove hits for visitorId and keep the consent hits
    override func flushTrackAndKeepConsent(_ visitorId: String) {
        // Remove from the pool and get the ids for the deleted ones
        var listIdsToRemove = batchManager.flushTrackAndKeepConsent(visitorId)
        if !listIdsToRemove.isEmpty {
            // Remove them fom the database
            cacheManager?.flushHits(listIdsToRemove)
        }
    }
}
