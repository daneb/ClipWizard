import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

// Enums for image processing
enum ImageFilter: String, CaseIterable, Identifiable {
    case none = "None"
    case grayscale = "Grayscale"
    case sepia = "Sepia"
    case invert = "Invert"
    case blur = "Blur"
    case sharpen = "Sharpen"
    
    var id: String { rawValue }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"
    case bmp = "BMP"
    
    var id: String { rawValue }
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .tiff: return "tiff"
        case .bmp: return "bmp"
        }
    }
    
    var uniformTypeIdentifier: UTType {
        switch self {
        case .png: return UTType.png
        case .jpeg: return UTType.jpeg
        case .tiff: return UTType.tiff  
        case .bmp: return UTType.bmp
        }
    }
}

// Helper methods for image processing
class ImageProcessor {
    // Calculate and format file size
    static func calculateFileSize(_ image: NSImage) -> String {
        guard let tiffData = image.tiffRepresentation else {
            return "Unknown"
        }
        
        let bytes = tiffData.count
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // Apply various image adjustments
    static func applyAdjustments(to originalImage: NSImage, 
                                brightness: Double, 
                                contrast: Double, 
                                filter: ImageFilter,
                                rotationAngle: Double = 0) -> NSImage? {
        
        // Convert NSImage to CIImage for processing
        guard let cgImage = originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        
        // Create a CIContext for rendering
        let context = CIContext(options: nil)
        
        // Apply adjustments
        var processedImage = ciImage
        
        // Apply adjustments in sequence
        // Create a ColorControls filter for both brightness and contrast in one step
        if brightness != 0 || contrast != 1.0 {
            let adjustmentFilter = CIFilter.colorControls()
            adjustmentFilter.inputImage = processedImage
            adjustmentFilter.brightness = Float(brightness)
            adjustmentFilter.contrast = Float(contrast)
            adjustmentFilter.saturation = 1.0 // Keep saturation neutral
            
            if let outputImage = adjustmentFilter.outputImage {
                processedImage = outputImage
            }
        }
        
        // Apply selected filter
        switch filter {
        case .grayscale:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = processedImage
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = processedImage
            filter.intensity = 0.8
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .invert:
            let filter = CIFilter.colorInvert()
            filter.inputImage = processedImage
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .blur:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = processedImage
            filter.radius = 3
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .sharpen:
            let filter = CIFilter.sharpenLuminance()
            filter.inputImage = processedImage
            filter.sharpness = 0.5
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .none:
            // No filter applied
            break
        }
        
        // Convert CIImage back to NSImage
        if let cgOutput = context.createCGImage(processedImage, from: processedImage.extent) {
            let newImage = NSImage(cgImage: cgOutput, size: originalImage.size)
            
            // Apply rotation if needed (this is done after filters because rotation is a geometric operation)
            if rotationAngle != 0 && rotationAngle != 360 {
                // Rotation is applied in the UI via SwiftUI's .rotationEffect to avoid pixelation
                // For saving and exporting, we would need to actually rotate the image data
            }
            
            return newImage
        }
        
        return nil
    }
    
    // Save the image to disk with the specified format
    static func saveImageToDisk(image: NSImage, format: ExportFormat) {
        let savePanel = NSSavePanel()
        // Create array of allowed content types
        let contentTypes = [format.uniformTypeIdentifier]
        savePanel.allowedContentTypes = contentTypes
        savePanel.nameFieldStringValue = "ClipWizard_Image_\(Int(Date().timeIntervalSince1970))"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                if let tiffData = image.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData) {
                    // Export in the selected format
                    var imageProperties: [NSBitmapImageRep.PropertyKey: Any] = [:]
                    let formatType: NSBitmapImageRep.FileType
                    
                    switch format {
                    case .png: 
                        formatType = .png
                    case .jpeg: 
                        formatType = .jpeg
                        // Add JPEG compression quality (0.9 = 90% quality)
                        imageProperties[.compressionFactor] = 0.9
                    case .tiff: 
                        formatType = .tiff
                    case .bmp: 
                        formatType = .bmp
                    }
                    
                    if let imageData = bitmapImage.representation(using: formatType, properties: imageProperties) {
                        do {
                            try imageData.write(to: url)
                            print("Image saved successfully to: \(url.path)")
                        } catch {
                            print("Failed to save image: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    // Perform OCR on the image
    static func performOCR(on image: NSImage, completion: @escaping (String) -> Void) {
        // Convert NSImage to CGImage for Vision framework
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion("OCR failed: Could not convert image")
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion("OCR failed: \(error.localizedDescription)")
                }
                return
            }
            
            // Process the recognized text
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Join with newlines instead of spaces to better preserve text layout
            let result = recognizedStrings.joined(separator: "\n")
            
            DispatchQueue.main.async {
                completion(result.isEmpty ? "No text found in image" : result)
            }
        }
        
        // Configure the request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Start the OCR process
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion("OCR processing failed")
                }
            }
        }
    }
}
