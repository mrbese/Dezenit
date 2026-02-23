import SwiftUI
import SwiftData
import UIKit

struct BillSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var bill: EnergyBill
    @State private var showingPhoto = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                VStack(spacing: 12) {
                    if let name = bill.utilityName {
                        Text(name)
                            .font(.title2.bold())
                            .foregroundStyle(Color.manor.onPrimary)
                    }

                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(Int(bill.totalKWh))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.manor.onPrimary)
                            Text("kWh")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        VStack(spacing: 4) {
                            Text(String(format: "$%.2f", bill.totalCost))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.manor.onPrimary)
                            Text("Total")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.manor.primary, in: RoundedRectangle(cornerRadius: 20))

                // Details
                VStack(spacing: 0) {
                    detailRow(label: "Rate", value: String(format: "$%.3f/kWh", bill.computedRate))

                    if let start = bill.billingPeriodStart, let end = bill.billingPeriodEnd {
                        let formatter = DateFormatter()
                        let _ = (formatter.dateStyle = .medium)
                        detailRow(label: "Period", value: "\(formatter.string(from: start)) – \(formatter.string(from: end))")
                    }

                    if let days = bill.billingDays {
                        detailRow(label: "Billing Days", value: "\(days)")
                    }

                    if let daily = bill.dailyAverageKWh {
                        detailRow(label: "Daily Average", value: String(format: "%.1f kWh/day", daily))
                    }

                    if let annual = bill.annualizedKWh {
                        detailRow(label: "Annualized", value: "\(Int(annual)) kWh/yr")
                    }

                    detailRow(label: "Added", value: {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        return formatter.string(from: bill.createdAt)
                    }(), isLast: true)
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.manor.background.opacity(0.04), radius: 4, y: 1)

                // Photo
                if let data = bill.photoData, let image = UIImage(data: data) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bill Photo")
                            .font(.headline)

                        Button {
                            showingPhoto = true
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Bill Summary")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingPhoto) {
            if let data = bill.photoData, let image = UIImage(data: data) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                .onTapGesture { showingPhoto = false }
            }
        }
    }

    private func detailRow(label: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !isLast {
                Divider().padding(.leading, 16)
            }
        }
    }
}
