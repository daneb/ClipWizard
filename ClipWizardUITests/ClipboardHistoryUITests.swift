import XCTest

final class ClipboardHistoryUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests.
        // The setUp method is a good place to do this.
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // Add a flag to put the app in testing mode
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func openClipboardHistory() {
        // Assuming the app initially opens with the menu bar icon
        // Click on menu bar icon to open the popover
        let statusItem = XCUIApplication(bundleIdentifier: "com.apple.controlcenter").statusItems.firstMatch
        statusItem.click()
        
        // Wait for the popover to appear
        let historyTabExists = app.buttons["History"].waitForExistence(timeout: 5)
        XCTAssertTrue(historyTabExists, "History tab should exist")
        
        // Make sure we're on the History tab
        app.buttons["History"].click()
    }
    
    // MARK: - Tests
    
    func testClipboardHistoryTabExists() {
        openClipboardHistory()
        
        XCTAssertTrue(app.buttons["History"].exists, "History tab should exist")
        XCTAssertTrue(app.searchFields.firstMatch.exists, "Search field should exist in history view")
    }
    
    func testSearchFunctionality() {
        openClipboardHistory()
        
        // Tap on search field
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        
        // Enter search text
        searchField.typeText("test")
        
        // Check that the search is active
        XCTAssertEqual(searchField.value as? String, "test", "Search field should contain the search text")
        
        // Clear search
        searchField.buttons["Clear text"].tap()
        
        // Verify search field is cleared
        XCTAssertNotEqual(searchField.value as? String, "test", "Search field should be cleared")
    }
    
    func testNavigationBetweenTabs() {
        openClipboardHistory()
        
        // Initially on History tab
        XCTAssertTrue(app.buttons["History"].isSelected, "History tab should be selected initially")
        
        // Navigate to Settings tab
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Settings"].isSelected, "Settings tab should be selected after clicking")
        XCTAssertFalse(app.buttons["History"].isSelected, "History tab should not be selected")
        
        // Go back to History tab
        app.buttons["History"].tap()
        XCTAssertTrue(app.buttons["History"].isSelected, "History tab should be selected again")
        XCTAssertFalse(app.buttons["Settings"].isSelected, "Settings tab should not be selected")
    }
    
    func testClipboardItemSelection() {
        openClipboardHistory()
        
        // Check if there are any clipboard items
        let firstClipboardItem = app.tables.cells.firstMatch
        
        if firstClipboardItem.exists {
            // Click on the first clipboard item
            firstClipboardItem.tap()
            
            // There should be some indication of selection or copying
            // This might be a notification, or the item might change appearance
            // For now, we'll just check that the item still exists after clicking
            XCTAssertTrue(firstClipboardItem.exists, "Clipboard item should still exist after selection")
        } else {
            XCTFail("No clipboard items found for testing. Add some test data.")
        }
    }
    
    func testClearHistoryButton() {
        openClipboardHistory()
        
        // Look for the clear history button
        let clearButton = app.buttons["Clear History"]
        
        if clearButton.exists {
            // Click the clear button
            clearButton.tap()
            
            // There should be a confirmation dialog
            let confirmButton = app.buttons["Confirm"]
            XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "Confirmation dialog should appear")
            
            // Cancel the clear operation for the test
            app.buttons["Cancel"].tap()
        } else {
            XCTFail("Clear History button not found")
        }
    }
    
    func testSettingsTabComponents() {
        openClipboardHistory()
        
        // Navigate to Settings tab
        app.buttons["Settings"].tap()
        
        // Check for settings tab components
        XCTAssertTrue(app.buttons["General"].exists, "General settings tab should exist")
        XCTAssertTrue(app.buttons["Rules"].exists, "Rules settings tab should exist")
        XCTAssertTrue(app.buttons["Hotkeys"].exists, "Hotkeys settings tab should exist")
        XCTAssertTrue(app.buttons["Logs"].exists, "Logs tab should exist")
    }
}
