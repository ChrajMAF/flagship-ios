//
//  FSBucketManager.swift
//  FlagShip-framework
//
//  Created by Adel on 21/11/2019.
//

import Foundation

/// :nodoc:
class FSBucketManager: NSObject {

    let targetManager: FSTargetingManager!

    var matchedVariationGroup: [FSVariationGroup] = [] // Init with empty array

    var matchedCampaigns: [FSCampaignCache] = []

    override init() {

        targetManager = FSTargetingManager()

    }

    /// This is the entry for bucketing , that give the campaign infos as we do in api decesion
    internal func bucketVariations(_ visitorId: String, _ scriptBucket: FSBucket) -> FSCampaigns? {

        /// Check the panic mode

        if scriptBucket.panic == true {
            
            return FSCampaigns(visitorId, panic: true)
        }

        // check if the user exist in the cache , if yes then read his own modification from the cache

        // If not extract the variations

        // check the targetings and filter the variation he can run

        // Match before
        let resultBucketCache = matchTargetingForCustomID(scriptBucket, visitorId, scriptBucket.visitorConsolidation)

        // Save My bucketing
        resultBucketCache.saveMe()

        // Fill Campaign with value to be read by singleton
        return FSCampaigns(resultBucketCache)
    }

    /// Extract the variations where the user is allowed to seee

    internal func matchTargetingForCustomID(_ scriptBucket: FSBucket?, _ visitorId: String, _ visitorConsolidation: Bool) -> FSBucketCache {

        let fsCampaignBucketCache = FSBucketCache(visitorId)

        matchedVariationGroup.removeAll()

        var groupCampaigns: [FSCampaignCache] = []
        var groupVar: [FSVariationGroupCache] = []

        groupCampaigns.removeAll()

        if let campaignsArray = scriptBucket?.campaigns {

            for bucketCampaignItem: FSBucketCampaign in campaignsArray {
                groupVar.removeAll()

                for variationGroupItem: FSVariationGroup in bucketCampaignItem.variationGroups {

                    if targetManager.isTargetingGroupIsOkay(variationGroupItem.targeting) {

                        FSLogger.FSlog("Target for \(variationGroupItem.idVariationGroup ?? "") is OKAY", .Campaign)

                        // select variation here
                        guard let variationIdSelected = selectVariationWithHashMurMur(visitorId, variationGroupItem, visitorConsolidation) else {

                            FSLogger.FSlog("probleme here don 't found the id variation selected", .Campaign)

                            continue

                        }

                        /// Get all modification according to id variation

                        let variationCache: FSVariationCache = FSVariationCache(variationIdSelected)

                        for itemVariation in variationGroupItem.variations {

                            if itemVariation.idVariation == variationIdSelected {

                                /// the variationIdSelected is found , populate the attributes 
                                variationCache.modification = itemVariation.modifications
                                variationCache.reference = itemVariation.reference
                            }
                        }

                        groupVar.append(FSVariationGroupCache(variationGroupItem.idVariationGroup, variationCache))

                    } else {

                        FSLogger.FSlog("Target for \(variationGroupItem.idVariationGroup ?? "") is NOK", .Campaign)

                    }
                }
                groupCampaigns.append(FSCampaignCache(bucketCampaignItem.idCampaign, groupVar))
            }

        }
        fsCampaignBucketCache.campaigns = groupCampaigns

        return fsCampaignBucketCache
    }

    internal func selectVariationWithHashMurMur(_ visitorId: String, _ variationGroup: FSVariationGroup, _ visitorConsolidation: Bool) -> String? {

        // Before selected varaition have to chck user id exist

        if FSStorage.fileExists(String(format: "%@.json", visitorId), in: .documents) {

            FSLogger.FSlog("The Buketing already exist Will Re check targeting for the selected variation ", .Campaign)

            guard let cachedObject = FSStorage.retrieve(String(format: "%@.json", visitorId), from: .documents, as: FSBucketCache.self) else {

                FSLogger.FSlog(" Error on retreive cached object", .Campaign)

                return nil
            }

            for itemCached in cachedObject.campaigns {

                for subItemCached in itemCached.variationGroups {  /// Variation Group already exist, then return the saved one

                    if subItemCached.variationGroupId == variationGroup.idVariationGroup {

                        return subItemCached.variation.variationId
                    }
                }
            }
        }

        let hashAlloc: Int

        FSLogger.FSlog("Apply MurMurHash Algo on customId", .Campaign)

        /// We calculate the Hash allocation by the combonation of : visitorId + idVariationGroup

        let combinedId = variationGroup.idVariationGroup + visitorId

        FSLogger.FSlog(" The combined id for MurMurHash is :  \(combinedId)", .Campaign)

        hashAlloc = (Int(MurmurHash3.hash32(key: combinedId) % 100))

        var offsetAlloc = 0
        for item: FSVariation in  variationGroup.variations {

            if hashAlloc < item.allocation + offsetAlloc {

                return item.idVariation
            }
            offsetAlloc += item.allocation
        }
        return nil
    }
}
