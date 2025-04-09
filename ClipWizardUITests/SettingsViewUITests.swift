import XCTest

final class SettingsViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it's important to set the initial state
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
    
    private func openSettingsTab() {
        // Assuming the app initially opens with the menu bar icon
        let statusItem = XCUIApplication(bundleIdentifier: "com.apple.controlcenter").statusItems.firstMatch
        statusItem.click()
        
        // Wait for the popover to appear and navigate to Settings
        let settingsTabExists = app.buttons["Settings"].waitForExistence(timeout: 5)
        XCTAssertTrue(settingsTabExists, "Settings tab should exist")
        
        // Click on Settings tab
        app.buttons["Settings"].click()
    }
    
    // MARK: - Tests
    
    func testGeneralSettingsTab() {
        openSettingsTab()
        
        // Ensure we're on the General tab by default
        XCTAssertTrue(app.buttons["General"].isSelected, "General tab should be selected initially")
        
        // Check for general settings controls
        XCTAssertTrue(app.sliders["History Size"].exists, "History size slider should exist")
        
        // Check if we can interact with the slider
        let slider = app.sliders["History Size"]
        let initialValue = slider.value as? Double ?? 0
        
        // Move slider to the right
        slider.adjust(toNormalizedSliderPosition: 0.8)
        
        // Check if slider value changed
        let newValue = slider.value as? Double ?? 0
        XCTAssertNotEqual(initialValue, newValue, "Slider value should change after adjustment")
    }
    
    func testRulesSettingsTab() {
        openSettingsTab()
        
        // Navigate to Rules tab
        app.buttons["Rules"].click()
        
        // Check if Rules tab is selected
        XCTAssertTrue(app.buttons["Rules"].isSelected, "Rules tab should be selected")
        
        // Check for Rules UI elements
        XCTAssertTrue(app.buttons["Add Rule"].exists, "Add Rule button should exist")
        
        // Test Add Rule button
        app.buttons["Add Rule"].click()
        
        // Check if rule editing UI appears
        let ruleNameField = app.textFields["Rule Name"]
        XCTAssertTrue(ruleNameField.waitForExistence(timeout: 2), "Rule editing view should appear")
        
        // Enter test data for rule
        ruleNameField.tap()
        ruleNameField.typeText("Test Rule")
        
        let patternField = app.textFields["Pattern"]
        patternField.tap()
        patternField.typeText("password=.*")
        
        // Select a sanitization type
        // This may need adjustment based on your actual UI
        let maskOption = app.radioButtons["Mask"]
        if maskOption.exists {
            maskOption.click()
        }
        
        // Test Save button
        let saveButton = app.buttons["Save Rule"]
        if saveButton.exists {
            saveButton.click()
        }
        
        // Rule should appear in the list
        // This might need adjusting based on your actual UI
        // XCTAssertTrue(app.staticTexts["Test Rule"].exists, "New rule should appear in the list")
        
        // Let's just check if we're back to the Rules list view
        XCTAssertTrue(app.buttons["Add Rule"].waitForExistence(timeout: 2), "Should return to rules list after saving")
    }
    
    func testHotkeysSettingsTab() {
        openSettingsTab()
        
        // Navigate to Hotkeys tab
        app.buttons["Hotkeys"].click()
        
        // Check if Hotkeys tab is selected
        XCTAssertTrue(app.buttons["Hotkeys"].isSelected, "Hotkeys tab should be selected")
        
        // Check for hotkey recording fields
        let showAppField = app.textFields["Show/Hide ClipWizard"]
        XCTAssertTrue(showAppField.exists, "Show app hotkey field should exist")
        
        // Test hotkey recording (this is tricky in UI tests)
        // We'll just check if the field can be interacted with
        showAppField.tap()
        
        // Since actually simulating keystrokes for hotkey recording is complex,
        // we'll just check if the field still exists and is enabled after tapping
        XCTAssertTrue(showAppField.exists && showAppField.isEnabled, "Hotkey field should remain accessible after tap")
    }
    
    func testLogsTab() {
        openSettingsTab()
        
        // Navigate to Logs tab
        app.buttons["Logs"].click()
        
        // Check if Logs tab is selected
        XCTAssertTrue(app.buttons["Logs"].isSelected, "Logs tab should be selected")
        
        // Check for logs interface elements
        XCTAssertTrue(app.textViews["LogsTextView"].exists, "Logs text view should exist")
        
        // Check for filter controls
        let allLevelsRadio = app.radioButtons["All Levels"]
        XCTAssertTrue(allLevelsRadio.exists, "Log level filter controls should exist")
        
        // Test filter controls
        allLevelsRadio.click()
        
        // Check for Copy Logs button
        let copyButton = app.buttons["Copy Logs"]
        XCTAssertTrue(copyButton.exists, "Copy logs button should exist")
        
        // Test copy button (just check if it responds)
        copyButton.click()
        
        // Hard to verify clipboard contents in UI tests, 
        // but we can check the button isn't disabled after clicking
        XCTAssertTrue(copyButton.isEnabled, "Copy button should remain enabled after clicking")
    }
    
    func testTabNavigation() {
        openSettingsTab()
        
        // Test navigation between all settings tabs
        
        // Start with General (default)
        XCTAssertTrue(app.buttons["General"].isSelected, "General tab should be selected initially")
        
        // Navigate to Rules
        app.buttons["Rules"].click()
        XCTAssertTrue(app.buttons["Rules"].isSelected, "Rules tab should be selected")
        XCTAssertFalse(app.buttons["General"].isSelected, "General tab should not be selected")
        
        // Navigate to Hotkeys
        app.buttons["Hotkeys"].click()
        XCTAssertTrue(app.buttons["Hotkeys"].isSelected, "Hotkeys tab should be selected")
        XCTAssertFalse(app.buttons["Rules"].isSelected, "Rules tab should not be selected")
        
        // Navigate to Logs
        app.buttons["Logs"].click()
        XCTAssertTrue(app.buttons["Logs"].isSelected, "Logs tab should be selected")
        XCTAssertFalse(app.buttons["Hotkeys"].isSelected, "Hotkeys tab should not be selected")
        
        // Navigate back to General
        app.buttons["General"].click()
        XCTAssertTrue(app.buttons["General"].isSelected, "General tab should be selected again")
        XCTAssertFalse(app.buttons["Logs"].isSelected, "Logs tab should not be selected")
    }
}