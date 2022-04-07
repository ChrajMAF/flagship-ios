//
//  FSCampaignsTest.swift
//  FlagshipTests
//
//  Created by Adel on 01/04/2020.
//  Copyright © 2020 FlagShip. All rights reserved.
//

import XCTest
@testable import Flagship

class FSCampaignsTest: XCTestCase {

    var campaignTest: FSCampaigns?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // Read the data from the file and fil the campaigns
         do {

             let testBundle = Bundle(for: type(of: self))

             guard let path = testBundle.url(forResource: "decisionApi", withExtension: "json") else { return  }

             let data = try Data(contentsOf: path, options: .alwaysMapped)

              campaignTest = try JSONDecoder().decode(FSCampaigns.self, from: data)

         } catch {

             print("error")
         }

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        campaignTest = nil
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testGetRelativeInfoTrackForValue() {

        XCTAssertNil(campaignTest?.getRelativeInfoTrackForValue(""))

        // ["vaid": item.variation?.idVariation ?? "", "caid":item.variationGroupId ?? ""]
        if let dico = campaignTest?.getRelativeInfoTrackForValue("alias") {

            XCTAssertEqual(dico.keys.count, 2)

            XCTAssertEqual(dico["vaid"], "bsffhle242b2l3igq4f0")

            XCTAssertEqual(dico["caid"] , "bsffhle242b2l3igq4egaa")
        }

        //
        if let dicoBis = campaignTest?.getRelativeInfoTrackForValue("aliasTer") {

            XCTAssertEqual(dicoBis["vaid"] , "")

            XCTAssertEqual(dicoBis["caid"] , "")
        }
        
        /// Check the relative infos for activate on the duplicated key
        if let dico = campaignTest?.getRelativeInfoTrackForValue("duplicateKey") {

            XCTAssertEqual(dico.keys.count, 2)

            XCTAssertEqual(dico["vaid"], "c82ta57u5lig4c8poerg")

            XCTAssertEqual(dico["caid"] , "c82ta57u5lig4c8poeqg")
        }
    }

    func testGetRelativekeyModificationInfos() {
        
        XCTAssertNil(campaignTest?.getRelativekeyModificationInfos(""))

        // ["campaignId" : item.idCampaign, "variationId": item.variation?.idVariation ?? "", "variationGroupId":item.variationGroupId ?? "","isReference":true]
        if let dico = campaignTest?.getRelativekeyModificationInfos("alias") {

            XCTAssertEqual(dico.keys.count, 4)

            XCTAssertEqual(dico["campaignId"] as? String, "bsffhle242b2l3igq4dg")

            XCTAssertEqual(dico["variationId"] as? String, "bsffhle242b2l3igq4f0")

            XCTAssertEqual(dico["variationGroupId"] as? String, "bsffhle242b2l3igq4egaa")

            XCTAssertEqual(dico["isReference"] as? Bool, true)

        }

    }

}
