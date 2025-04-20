//
//  ClipWizardUITestsLaunchTests.swift
//  ClipWizardUITests
//
//  Created by Dane Balia on 2025/03/30.
//

import XCTest

final class ClipWizardUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // Simple test that just launches the app without assertions
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // Use the test mode
        app.launch()
        
        // Just verify the app exists and launched
        XCTAssertTrue(app.exists, "App should be running")
    }
}
