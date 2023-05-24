//
//  FSPeriodicTrackingManager.swift
//  Flagship
//
//  Created by Adel Ferguen on 27/03/2023.
//  Copyright © 2023 FlagShip. All rights reserved.
//

import Foundation

class PeriodicTrackingManager: ContinuousTrackingManager {
    // Create batch manager

    override init(_ pService: FSService, _ pTrackingConfig: FSTrackingConfig, _ pCacheManager: FSCacheManager) {
        super.init(pService, pTrackingConfig, pCacheManager)
    }

    override func sendHit(_ hitToSend: FSTrackingProtocol) {
        if hitToSend.isValid() {
            batchManager.addTrackElement(hitToSend)

        } else {
            FlagshipLogManager.Log(level: .ALL, tag: .TRACKING, messageToDisplay: FSLogMessage.MESSAGE("hit not valide to be sent "))
        }
    }

//    override func sendActivate(_ currentActivate: Activate?) {
//        print("---------- Send Activate, PeriodicTrackingManager ----------")
//    }

    override internal func onSucessToSendHits(_ batchToSend: FSBatch) {
        print("---------- On Sucess To Send Hit, PeriodicTrackingManager ----------")

        // Clear all hits in database
        cacheManager?.flushAllHits()
        // Get the merged hit from pool
        let remainedHitInQueue = batchManager.getTrackElement()
        if !remainedHitInQueue.isEmpty { // TODO: LATER FIXING
            for itemToSave in remainedHitInQueue {
                // Save hit in Database
                let cacheHit: FSCacheHit = .init(itemToSave) // Convert to cache format
                cacheManager?.cacheHits(hits: [itemToSave.id: cacheHit.jsonCacheFormat() ?? [:]])
            }
        }
    }

    override internal func onFailedToSendHits(_ batchToSend: FSBatch) {
        print("---------- On Failed To Send Hit, PeriodicTrackingManager ----------")
        // Reinject the failed hits into the queue
        batchManager.reInjectElements(listToReInject: batchToSend.items)

        // Save the merged hit pool and activate
        var remainedHitInQueue = batchManager.getTrackElement(activatePool: true)
        // add the hit pool
        remainedHitInQueue.append(contentsOf: batchManager.getTrackElement())
        // Clear all hits in database
        cacheManager?.flushAllHits()
        if !remainedHitInQueue.isEmpty {
            for itemToSave in remainedHitInQueue {
                // Save hit in Database
                let cacheHit: FSCacheHit = .init(itemToSave) // Convert to cache format
                cacheManager?.cacheHits(hits: [itemToSave.id: cacheHit.jsonCacheFormat() ?? [:]])
            }
        }
    }

    override internal func onSucessToSendActivate(_ activateBatch: ActivateBatch) {
        print("---------- On Sucess To Send Activate, PeriodicTrackingManager ----------")
    }

    // Remove hits for visitorId and keep the consent hits
    override func flushTrackAndKeepConsent(_ visitorId: String) {
        //// HITS********
        // Flush hit queueue and keep the consent ones
        let unwantedHits = batchManager.flushTrackAndKeepConsent(visitorId)
        // delete unwanted hits
        cacheManager?.flushHits(unwantedHits)
        ////ACTIVATE******
        // Flush the activate from the  queueue
        let unwantedActivate = batchManager.extractAllElements(activatePool: true)
        // Flush all activate from the database
        cacheManager?.flushHits(unwantedActivate.map { elem in
            elem.id
        })
    }
}
