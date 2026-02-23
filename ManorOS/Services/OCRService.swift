import Foundation
import Vision
import UIKit

struct OCRResult {
    var manufacturer: String?
    var modelNumber: String?
    var efficiencyValue: Double?
    var efficiencyType: String? // "SEER", "AFUE", "UEF", etc.
    var btuCapacity: Int?
    var rawText: String
}

enum OCRService {

    private static let knownManufacturers = [
        "carrier", "trane", "lennox", "goodman", "rheem", "york",
        "daikin", "mitsubishi", "bosch", "ao smith", "a.o. smith",
        "bradford white", "navien", "rinnai", "amana", "bryant",
        "ruud", "heil", "payne", "coleman", "frigidaire", "lg",
        "samsung", "whirlpool", "ge", "general electric", "maytag",
        "kenmore", "speed queen", "electrolux", "honeywell", "ecobee",
        "nest", "emerson", "sensi", "pella", "andersen", "marvin",
        "milgard", "jeld-wen"
    ]

    private static let efficiencyPatterns: [(pattern: String, label: String)] = [
        (#"SEER2?\s*[:=]?\s*(\d+\.?\d*)"#, "SEER"),
        (#"EER\s*[:=]?\s*(\d+\.?\d*)"#, "EER"),
        (#"CEER\s*[:=]?\s*(\d+\.?\d*)"#, "CEER"),
        (#"HSPF2?\s*[:=]?\s*(\d+\.?\d*)"#, "HSPF"),
        (#"AFUE\s*[:=]?\s*(\d+\.?\d*)\s*%?"#, "AFUE"),
        (#"UEF\s*[:=]?\s*(\d+\.?\d*)"#, "UEF"),
        (#"U-?[Ff]actor\s*[:=]?\s*(\d+\.?\d*)"#, "U-factor"),
        (#"R-?[Vv]alue\s*[:=]?\s*R?-?(\d+\.?\d*)"#, "R-value"),
        (#"IMEF\s*[:=]?\s*(\d+\.?\d*)"#, "IMEF"),
        (#"CEF\s*[:=]?\s*(\d+\.?\d*)"#, "CEF"),
    ]

    static func recognizeText(from image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(rawText: "")
        }

        let allText = await performOCR(on: cgImage)
        return parseOCRText(allText)
    }

    private static func performOCR(on cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let allText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: allText)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    static func parseOCRText(_ text: String) -> OCRResult {
        var result = OCRResult(rawText: text)
        let lowered = text.lowercased()

        // Find manufacturer
        for mfr in knownManufacturers {
            if lowered.contains(mfr) {
                result.manufacturer = mfr.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
                break
            }
        }

        // Find efficiency values
        for (pattern, label) in efficiencyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range),
                   match.numberOfRanges > 1,
                   let valueRange = Range(match.range(at: 1), in: text),
                   let value = Double(text[valueRange]) {
                    result.efficiencyValue = value
                    result.efficiencyType = label
                    break
                }
            }
        }

        // Find model number (alphanumeric string 8-20 chars, typically starts with letter)
        let modelPattern = #"[A-Z][A-Z0-9\-]{7,19}"#
        if let regex = try? NSRegularExpression(pattern: modelPattern) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let matchRange = Range(match.range, in: text) {
                result.modelNumber = String(text[matchRange])
            }
        }

        // Find BTU capacity
        let btuPattern = #"(\d{1,3}[,.]?\d{3})\s*BTU"#
        if let regex = try? NSRegularExpression(pattern: btuPattern, options: .caseInsensitive) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               match.numberOfRanges > 1,
               let valueRange = Range(match.range(at: 1), in: text) {
                let numStr = text[valueRange].replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")
                result.btuCapacity = Int(numStr)
            }
        }

        return result
    }
}
