import SwiftUI

enum RideType: String, CaseIterable, Identifiable {
    case economy = "Economy"
    case premium = "Premium"
    case suv = "SUV"

    var id: String { rawValue }

    var baseFare: Double {
        switch self {
        case .economy: return 4.0
        case .premium: return 8.0
        case .suv: return 10.0
        }
    }

    var perKilometerRate: Double {
        switch self {
        case .economy: return 1.2
        case .premium: return 2.0
        case .suv: return 2.6
        }
    }
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case applePay = "Apple Pay"
    case creditCard = "Credit Card"
    case cash = "Cash"

    var id: String { rawValue }
}

final class RideBookingViewModel: ObservableObject {
    @Published var pickupLocation: String = ""
    @Published var dropoffLocation: String = ""
    @Published var pickupTime: Date = Date()

    @Published var selectedRideType: RideType = .economy
    @Published var passengerCount: Int = 1
    @Published var selectedPaymentMethod: PaymentMethod = .applePay

    @Published var notesForDriver: String = ""

    @Published var isRequestingRide: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showConfirmation: Bool = false

    var canSubmit: Bool {
        let hasPickup = !pickupLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDropoff = !dropoffLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasPickup && hasDropoff && passengerCount > 0
    }

    func estimateDistanceKilometers() -> Double {
        guard !pickupLocation.isEmpty, !dropoffLocation.isEmpty else { return 0.0 }
        let seed = Double(abs(pickupLocation.hashValue ^ dropoffLocation.hashValue) % 1000) / 100.0
        return max(1.0, min(35.0, seed))
    }

    func estimateFare() -> Double {
        let distanceKm = estimateDistanceKilometers()
        let fare = selectedRideType.baseFare + (selectedRideType.perKilometerRate * distanceKm)
        return max(0, fare)
    }

    @MainActor
    func requestRide() async {
        guard canSubmit else { return }
        isRequestingRide = true
        errorMessage = nil
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            showConfirmation = true
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        isRequestingRide = false
    }
}

struct RideBookingView: View {
    @StateObject private var viewModel = RideBookingViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case pickup, dropoff, notes }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Pickup location", text: $viewModel.pickupLocation)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .pickup)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .dropoff }

                    TextField("Dropoff location", text: $viewModel.dropoffLocation)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .dropoff)
                        .submitLabel(.done)

                    DatePicker(
                        "Pickup time",
                        selection: $viewModel.pickupTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Options") {
                    Picker("Ride type", selection: $viewModel.selectedRideType) {
                        ForEach(RideType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Stepper(value: $viewModel.passengerCount, in: 1...6) {
                        HStack {
                            Text("Passengers")
                            Spacer()
                            Text("\(viewModel.passengerCount)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Payment", selection: $viewModel.selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }

                    TextField("Driver notes (optional)", text: $viewModel.notesForDriver, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($focusedField, equals: .notes)
                }

                Section("Estimate") {
                    HStack {
                        Text("Estimated distance")
                        Spacer()
                        Text(String(format: "%.1f km", viewModel.estimateDistanceKilometers()))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Estimated price")
                        Spacer()
                        Text(viewModel.canSubmit ? formatCurrency(viewModel.estimateFare()) : "—")
                            .bold()
                    }
                }

                Section {
                    Button(action: {
                        Task { await viewModel.requestRide() }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isRequestingRide {
                                ProgressView()
                            }
                            Text(viewModel.isRequestingRide ? "Requesting…" : "Request ride")
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isRequestingRide)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Book a Ride")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .alert("Ride requested!", isPresented: $viewModel.showConfirmation) {
                Button("OK", role: .cancel) { viewModel.showConfirmation = false }
            } message: {
                Text("Your \(viewModel.selectedRideType.rawValue) is on the way.")
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}

struct RideBookingView_Previews: PreviewProvider {
    static var previews: some View {
        RideBookingView()
    }
}