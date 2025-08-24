import SwiftUI

struct RideBookingView: View {
    @StateObject var viewModel: RideBookingViewModel

    var body: some View {
        Form {
            Section("Pickup and Dropoff") {
                TextField("Pickup location", text: $viewModel.pickupLocationText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                TextField("Dropoff location", text: $viewModel.dropoffLocationText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            Section("Details") {
                DatePicker("When", selection: $viewModel.rideDate, displayedComponents: [.date, .hourAndMinute])
                Picker("Ride type", selection: $viewModel.rideType) {
                    ForEach(RideType.allCases) { type in
                        Text("\(type.emoji) \(type.displayName)").tag(type)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Estimated distance")
                    Spacer()
                    Stepper(value: $viewModel.estimatedDistanceKilometers, in: 0.5...200, step: 0.5) {
                        Text("\(viewModel.estimatedDistanceKilometers, specifier: "%.1f") km")
                            .monospacedDigit()
                    }
                    .labelsHidden()
                }

                HStack {
                    Text("Fare estimate")
                    Spacer()
                    Text(viewModel.fareEstimate, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .bold()
                        .monospacedDigit()
                }
            }

            Section {
                Button {
                    Task { await viewModel.bookRide() }
                } label: {
                    if viewModel.isBookingInProgress {
                        ProgressView()
                    } else {
                        Text("Book Ride")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.isFormValid || viewModel.isBookingInProgress)
            }
        }
        .navigationTitle("Book a Ride")
        .alert("Ride Confirmed", isPresented: Binding(
            get: { viewModel.bookingConfirmation != nil },
            set: { if $0 == false { viewModel.bookingConfirmation = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let confirmation = viewModel.bookingConfirmation {
                Text("ETA: \(confirmation.etaMinutes) min\nFare: \(confirmation.quotedFare, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if $0 == false { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#if DEBUG
struct RideBookingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RideBookingView(viewModel: RideBookingViewModel(service: RideBookingService()))
        }
    }
}
#endif