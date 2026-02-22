import SwiftUI
import PDFKit

enum ReportPDFGenerator {

    @MainActor
    static func generatePDF(for home: Home) -> Data? {
        let reportView = HomeReportView(home: home)
            .frame(width: 612) // US Letter width in points

        let renderer = ImageRenderer(content: reportView)
        renderer.scale = 2.0

        let pdfData = NSMutableData()

        renderer.render { size, renderInContext in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }

            context.beginPDFPage(nil)
            renderInContext(context)
            context.endPDFPage()
            context.closePDF()
        }

        return pdfData.length > 0 ? pdfData as Data : nil
    }

    @MainActor
    static func savePDF(for home: Home) -> URL? {
        guard let data = generatePDF(for: home) else { return nil }

        let fileName = "\(home.name.isEmpty ? "Home" : home.name)_Report.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
