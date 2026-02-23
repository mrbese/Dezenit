import Foundation
import Vision
import UIKit

struct BulbOCRResult {
    var wattage: Double?
    var lumens: Int?
    var colorTemp: Int? // Kelvin
    var bulbType: ApplianceCategory? // ledBulb, cflBulb, incandescentBulb
    var rawText: String
}

enum LightingOCRService {

    /// OCR a bulb closeup photo and extract wattage, lumens, color temp, and bulb type.
    static func recognizeBulb(from image: UIImage) async -> BulbOCRResult {
        guard let cgImage = image.cgImage else {
            return BulbOCRResult(rawText: "")
        }

        let allText = await performOCR(on: cgImage)
        return parseBulbText(allText)
    }

    private static func performOCR(on cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let allText = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
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

    static func parseBulbText(_ text: String) -> BulbOCRResult {
        var result = BulbOCRResult(rawText: text)
        let lowered = text.lowercased()

        // Extract wattage: "9W", "60 Watt", "13.5W"
        let wattagePattern = #"(\d+\.?\d*)\s*[Ww](?:att)?(?:s)?\b"#
        if let regex = try? NSRegularExpression(pattern: wattagePattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text),
           let value = Double(text[range]) {
            result.wattage = value
        }

        // Extract lumens: "800 lm", "1100 lumens"
        let lumensPattern = #"(\d+)\s*(?:lm|lumens?)\b"#
        if let regex = try? NSRegularExpression(pattern: lumensPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text),
           let value = Int(text[range]) {
            result.lumens = value
        }

        // Extract color temperature: "2700K", "5000 K"
        let colorTempPattern = #"(\d{2,4})\s*[Kk]\b"#
        if let regex = try? NSRegularExpression(pattern: colorTempPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text),
           let value = Int(text[range]),
           value >= 1800 && value <= 7000 { // reasonable color temp range
            result.colorTemp = value
        }

        // Detect bulb type from text
        if lowered.contains("led") {
            result.bulbType = .ledBulb
        } else if lowered.contains("cfl") || lowered.contains("compact fluorescent") {
            result.bulbType = .cflBulb
        } else if lowered.contains("incandescent") || lowered.contains("halogen") {
            result.bulbType = .incandescentBulb
        }

        return result
    }
}
