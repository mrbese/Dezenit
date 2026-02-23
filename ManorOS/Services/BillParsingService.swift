import Foundation
import Vision
import UIKit

struct ParsedBillResult {
    var utilityName: String?
    var billingPeriodStart: Date?
    var billingPeriodEnd: Date?
    var totalKWh: Double?
    var totalCost: Double?
    var ratePerKWh: Double?
    var rawText: String
}

enum BillParsingService {

    /// Parse a utility bill image and extract billing data via OCR.
    static func parseBill(from image: UIImage) async -> ParsedBillResult {
        guard let cgImage = image.cgImage else {
            return ParsedBillResult(rawText: "")
        }
        let allText = await performOCR(on: cgImage)
        return parseBillText(allText)
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

    // MARK: - Text Parsing

    static func parseBillText(_ text: String) -> ParsedBillResult {
        var result = ParsedBillResult(rawText: text)

        result.totalKWh = extractKWh(from: text)
        result.totalCost = extractTotalCost(from: text)
        result.ratePerKWh = extractRate(from: text)
        result.utilityName = extractUtilityName(from: text)

        let dates = extractBillingDates(from: text)
        result.billingPeriodStart = dates.start
        result.billingPeriodEnd = dates.end

        // Derive rate if we have cost and kWh but no explicit rate
        if result.ratePerKWh == nil, let kwh = result.totalKWh, let cost = result.totalCost, kwh > 0 {
            result.ratePerKWh = cost / kwh
        }

        return result
    }

    // MARK: - Extractors

    private static func extractKWh(from text: String) -> Double? {
        // Match patterns like "1,234 kWh", "1234.5 kWh", "Usage: 1234 kWh"
        let pattern = #"(\d[\d,]*\.?\d*)\s*kWh"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let cleaned = text[range].replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private static func extractTotalCost(from text: String) -> Double? {
        // Try "Amount Due" or "Total" line first (most specific)
        let labeledPattern = #"(?:Amount\s*Due|Total\s*(?:Due|Charges?|Amount))[:\s]*\$\s*(\d[\d,]*\.\d{2})"#
        if let value = firstDouble(matching: labeledPattern, in: text) {
            return value
        }

        // Fall back to largest dollar amount on the bill (likely the total)
        let dollarPattern = #"\$\s*(\d[\d,]*\.\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: dollarPattern, options: .caseInsensitive) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var largest: Double = 0
        for match in matches {
            if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) {
                let cleaned = text[range].replacingOccurrences(of: ",", with: "")
                if let val = Double(cleaned), val > largest && val < 10_000 {
                    largest = val
                }
            }
        }
        return largest > 0 ? largest : nil
    }

    private static func extractRate(from text: String) -> Double? {
        // Match "12.5¢/kWh", "12.5 cents/kWh", "12.5 cents per kWh"
        let centsPattern = #"(\d+\.?\d*)\s*(?:¢|cents?)\s*(?:/|per)\s*kWh"#
        if let cents = firstDouble(matching: centsPattern, in: text) {
            return cents / 100.0
        }

        // Match "$0.165/kWh", "$0.16 per kWh"
        let dollarPattern = #"\$\s*(\d+\.\d+)\s*(?:/|per)\s*kWh"#
        if let rate = firstDouble(matching: dollarPattern, in: text) {
            return rate
        }

        return nil
    }

    private static func extractBillingDates(from text: String) -> (start: Date?, end: Date?) {
        // Look for date ranges like "Jan 15, 2024 - Feb 14, 2024" or "01/15/2024 to 02/14/2024"
        let dateFormats: [(pattern: String, format: String)] = [
            (#"(\w{3,9}\.?\s+\d{1,2},?\s+\d{4})"#, ""),  // parsed with multiple formatters
            (#"(\d{1,2}/\d{1,2}/\d{2,4})"#, "MM/dd/yyyy"),
            (#"(\d{1,2}-\d{1,2}-\d{2,4})"#, "MM-dd-yyyy"),
        ]

        var allDates: [Date] = []

        for (pattern, format) in dateFormats {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    let dateStr = String(text[range])
                    if let date = parseDate(dateStr, preferredFormat: format) {
                        allDates.append(date)
                    }
                }
            }
        }

        // Sort and take first two as start/end
        allDates.sort()
        // Filter to reasonable range (within last 2 years)
        let cutoff = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let recent = allDates.filter { $0 > cutoff && $0 <= Date() }

        if recent.count >= 2 {
            return (recent[0], recent[1])
        } else if recent.count == 1 {
            return (recent[0], nil)
        }
        return (nil, nil)
    }

    private static func extractUtilityName(from text: String) -> String? {
        let knownUtilities = [
            "PG&E", "Pacific Gas and Electric", "Pacific Gas & Electric",
            "SCE", "Southern California Edison",
            "SDG&E", "San Diego Gas & Electric", "San Diego Gas and Electric",
            "Con Edison", "Consolidated Edison", "ConEd",
            "Duke Energy", "Florida Power & Light", "FPL",
            "Dominion Energy", "Xcel Energy", "AEP", "American Electric Power",
            "National Grid", "Eversource", "Entergy",
            "ComEd", "Commonwealth Edison",
            "CenterPoint", "Oncor", "TXU Energy", "Reliant", "Gexa Energy",
            "Green Mountain Energy", "Direct Energy", "Cirro Energy",
            "APS", "Arizona Public Service", "Salt River Project", "SRP",
            "Georgia Power", "Alabama Power", "DTE Energy",
            "PECO", "PPL Electric", "Ameren",
        ]

        let lowered = text.lowercased()
        for name in knownUtilities {
            if lowered.contains(name.lowercased()) {
                return name
            }
        }
        return nil
    }

    // MARK: - Helpers

    private static func firstDouble(matching pattern: String, in text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let cleaned = text[range].replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private static func parseDate(_ string: String, preferredFormat: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if !preferredFormat.isEmpty {
            formatter.dateFormat = preferredFormat
            if let date = formatter.date(from: string) { return date }
            // Try 2-digit year variant
            if preferredFormat.contains("yyyy") {
                formatter.dateFormat = preferredFormat.replacingOccurrences(of: "yyyy", with: "yy")
                if let date = formatter.date(from: string) { return date }
            }
        }

        // Try common named-month formats
        let formats = [
            "MMM d, yyyy", "MMM d yyyy", "MMMM d, yyyy", "MMMM d yyyy",
            "MMM. d, yyyy", "MMM. d yyyy",
        ]
        for fmt in formats {
            formatter.dateFormat = fmt
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }
}
