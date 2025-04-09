import XCTest
@testable import ClipWizard
import Vision

final class ImageProcessingTests: XCTestCase {
    
    var testImage: NSImage!
    
    override func setUp() {
        super.setUp()
        
        // Create a test image
        // Using a small solid color image for testing
        let size = NSSize(width: 100, height: 100)
        testImage = NSImage(size: size)
        
        testImage.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: size.width, height: size.height).fill()
        testImage.unlockFocus()
    }
    
    override func tearDown() {
        testImage = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testCalculateFileSize() {
        // Test file size calculation
        let sizeString = ImageProcessor.calculateFileSize(testImage)
        
        // Size string should not be empty and should contain a number
        XCTAssertFalse(sizeString.isEmpty, "File size string should not be empty")
        
        // Since our test image is small, size should be in KB
        XCTAssertTrue(sizeString.contains("KB") || sizeString.contains("bytes"), "Small image size should be in KB or bytes")
    }
    
    func testApplyGrayscaleFilter() {
        // Apply grayscale filter
        let filteredImage = ImageProcessor.applyAdjustments(
            to: testImage,
            brightness: 0,
            contrast: 1.0,
            filter: .grayscale
        )
        
        // Verify we get an image back
        XCTAssertNotNil(filteredImage, "Should return a valid image after applying filter")
        
        // For a more comprehensive test, we could check pixel values
        // but that's outside the scope of this basic test
    }
    
    func testApplyBrightnessAdjustment() {
        // Apply brightness adjustment
        let brightImage = ImageProcessor.applyAdjustments(
            to: testImage,
            brightness: 0.5, // Increase brightness
            contrast: 1.0,
            filter: .none
        )
        
        // Verify we get an image back
        XCTAssertNotNil(brightImage, "Should return a valid image after brightness adjustment")
        
        // Apply negative brightness
        let darkImage = ImageProcessor.applyAdjustments(
            to: testImage,
            brightness: -0.5, // Decrease brightness
            contrast: 1.0,
            filter: .none
        )
        
        // Verify we get an image back
        XCTAssertNotNil(darkImage, "Should return a valid image after negative brightness adjustment")
    }
    
    func testApplyContrastAdjustment() {
        // Apply contrast adjustment
        let highContrastImage = ImageProcessor.applyAdjustments(
            to: testImage,
            brightness: 0,
            contrast: 1.5, // Increase contrast
            filter: .none
        )
        
        // Verify we get an image back
        XCTAssertNotNil(highContrastImage, "Should return a valid image after contrast adjustment")
        
        // Apply reduced contrast
        let lowContrastImage = ImageProcessor.applyAdjustments(
            to: testImage,
            brightness: 0,
            contrast: 0.5, // Decrease contrast
            filter: .none
        )
        
        // Verify we get an image back
        XCTAssertNotNil(lowContrastImage, "Should return a valid image after reduced contrast adjustment")
    }
    
    func testApplyAllFilters() {
        // Test all filter types
        for filter in ImageFilter.allCases {
            let filteredImage = ImageProcessor.applyAdjustments(
                to: testImage,
                brightness: 0,
                contrast: 1.0,
                filter: filter
            )
            
            // Verify we get an image back for each filter
            XCTAssertNotNil(filteredImage, "Should return a valid image after applying \(filter.rawValue) filter")
        }
    }
    
    func testCombinedAdjustments() {
        // Apply multiple adjustments
        let adjustedImage = ImageProcessor.applyAdjustments(
            to: testImage,
            brightness: 0.3,
            contrast: 1.2,
            filter: .sepia
        )
        
        // Verify we get an image back
        XCTAssertNotNil(adjustedImage, "Should return a valid image after combined adjustments")
    }
    
    func testRotationAngle() {
        // Apply rotation
        let rotatedImage = ImageProcessor.applyAdjustments(
            to: testImage,
            brightness: 0,
            contrast: 1.0,
            filter: .none,
            rotationAngle: 90
        )
        
        // Verify we get an image back
        XCTAssertNotNil(rotatedImage, "Should return a valid image after rotation")
    }
    
    func testPerformOCR() {
        // This is an async test that uses the Vision framework
        let expectation = self.expectation(description: "OCR Completion")
        
        // Create a test image with text
        let size = NSSize(width: 200, height: 50)
        let textImage = NSImage(size: size)
        
        textImage.lockFocus()
        // White background
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: size.width, height: size.height).fill()
        
        // Black text
        NSColor.black.set()
        let text = "ClipWizard Test"
        let font = NSFont.systemFont(ofSize: 24)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        text.draw(at: NSPoint(x: 10, y: 15), withAttributes: attributes)
        
        textImage.unlockFocus()
        
        // Perform OCR
        ImageProcessor.performOCR(on: textImage) { result in
            // The result should contain our test text
            XCTAssertTrue(result.contains("ClipWizard") || result.contains("Test"), 
                          "OCR result should contain text from the image: \(result)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPoorQualityImageOCR() {
        // Test OCR on a poor quality image (just our blue square)
        let expectation = self.expectation(description: "OCR Completion")
        
        ImageProcessor.performOCR(on: testImage) { result in
            // Since our test image has no text, it should indicate that
            XCTAssertTrue(result.contains("No text found") || result.isEmpty, 
                          "OCR on image without text should indicate no text found")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testExportFormatProperties() {
        // Test all export formats have correct properties
        for format in ExportFormat.allCases {
            // Test file extension
            XCTAssertFalse(format.fileExtension.isEmpty, "Format \(format.rawValue) should have a file extension")
            
            // Test UTType
            XCTAssertNotNil(format.uniformTypeIdentifier, "Format \(format.rawValue) should have a UTType")
        }
    }
    
    func testPerformanceOfImageProcessing() {
        // Create a larger test image for performance testing
        let size = NSSize(width: 1000, height: 1000)
        let largeImage = NSImage(size: size)
        
        largeImage.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: size.width, height: size.height).fill()
        largeImage.unlockFocus()
        
        // Measure performance of applying multiple adjustments
        measure {
            _ = ImageProcessor.applyAdjustments(
                to: largeImage,
                brightness: 0.3,
                contrast: 1.2,
                filter: .blur
            )
        }
    }
}
