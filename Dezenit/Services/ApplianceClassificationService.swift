import Foundation
import Vision
import UIKit

struct ClassificationResult: Identifiable {
    let id = UUID()
    let category: ApplianceCategory
    let confidence: Float
    let rawIdentifier: String
}

enum ApplianceClassificationService {

    /// Maps VNClassification identifiers to ApplianceCategory.
    /// VNClassifyImageRequest uses the built-in classifier with ~1000+ categories.
    private static let identifierMapping: [String: ApplianceCategory] = [
        // Entertainment
        "television": .television,
        "TV": .television,
        "screen": .television,
        "monitor": .monitor,
        "desktop computer": .desktop,
        "computer": .desktop,
        "laptop": .laptop,
        "notebook": .laptop,
        "joystick": .gamingConsole,
        "loudspeaker": .soundbar,
        "speaker": .soundbar,

        // Kitchen
        "refrigerator": .refrigerator,
        "washer": .dishwasher,
        "dishwasher": .dishwasher,
        "microwave": .microwave,
        "oven": .oven,
        "stove": .oven,
        "toaster": .toaster,
        "coffee maker": .coffeeMaker,
        "espresso maker": .coffeeMaker,
        "coffeepot": .coffeeMaker,

        // Lighting
        "lamp": .lampFixture,
        "table lamp": .lampFixture,
        "lampshade": .lampFixture,
        "spotlight": .floodlight,

        // Computing
        "keyboard": .desktop,
        "mouse": .desktop,
        "modem": .router,

        // Other
        "electric fan": .ceilingFan,
        "space heater": .portableHeater,
    ]

    /// Classify an image using Apple's built-in VNClassifyImageRequest.
    /// Returns top-K results mapped to ApplianceCategory.
    static func classify(image: UIImage, topK: Int = 3) async -> [ClassificationResult] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let observations = request.results as? [VNClassificationObservation],
                      error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                var results: [ClassificationResult] = []
                var seenCategories: Set<String> = []

                for obs in observations where obs.confidence > 0.05 {
                    if let category = mapToCategory(obs.identifier),
                       !seenCategories.contains(category.rawValue) {
                        seenCategories.insert(category.rawValue)
                        results.append(ClassificationResult(
                            category: category,
                            confidence: obs.confidence,
                            rawIdentifier: obs.identifier
                        ))
                    }
                    if results.count >= topK { break }
                }

                // If no matches, return generic "other" so user can pick manually
                if results.isEmpty {
                    results.append(ClassificationResult(
                        category: .other,
                        confidence: 0,
                        rawIdentifier: observations.first?.identifier ?? "unknown"
                    ))
                }

                continuation.resume(returning: results)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    /// Map a VNClassification identifier to our ApplianceCategory
    private static func mapToCategory(_ identifier: String) -> ApplianceCategory? {
        let lowered = identifier.lowercased()

        // Direct match
        if let category = identifierMapping[identifier] {
            return category
        }

        // Substring match
        for (key, category) in identifierMapping {
            if lowered.contains(key.lowercased()) {
                return category
            }
        }

        return nil
    }
}
