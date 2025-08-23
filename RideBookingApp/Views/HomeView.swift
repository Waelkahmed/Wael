import SwiftUI
import MapKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            MapViewRepresentable(
                userLocation: viewModel.locationManager.userLocation,
                destinationCoordinate: viewModel.destinationCoordinate,
                routePolyline: viewModel.route?.polyline
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                searchBar

                if !viewModel.suggestions.isEmpty && !viewModel.searchQuery.isEmpty {
                    suggestionsList
                }

                Spacer()
            }

            VStack {
                Spacer()
                bottomCard
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear { viewModel.onAppear() }
        .alert("Ride Requested", isPresented: Binding(
            get: { viewModel.bookingConfirmation != nil },
            set: { if $0 == false { viewModel.bookingConfirmation = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let c = viewModel.bookingConfirmation {
                Text("ETA: \(HomeViewModel.formatETA(Double(c.etaMinutes) * 60))\nFare: \(c.quotedFare, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.bookingError != nil },
            set: { if $0 == false { viewModel.bookingError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.bookingError ?? "")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Where to?", text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.onSearchQueryChange($0) }
            ))
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.suggestions = []
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var suggestionsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.selectSuggestion(suggestion)
                        viewModel.searchQuery = suggestion.title
                        viewModel.suggestions = []
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.title)
                                .foregroundColor(.primary)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                    }
                    Divider()
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var bottomCard: some View {
        VStack(spacing: 12) {
            Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 40, height: 4).padding(.top, 8)

            HStack {
                if let route = viewModel.route {
                    Text(viewModel.etaText).bold()
                    Text("· \(route.distance / 1000, specifier: "%.1f") km")
                        .foregroundColor(.secondary)
                } else {
                    Text("Set destination").foregroundColor(.secondary)
                }
                Spacer()
                Text(viewModel.fareEstimate, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .bold()
                    .monospacedDigit()
            }

            Picker("Ride type", selection: $viewModel.rideType) {
                ForEach(RideType.allCases) { type in
                    Text("\(type.emoji) \(type.displayName)").tag(type)
                }
            }
            .pickerStyle(.segmented)

            Button {
                Task { await viewModel.bookRide() }
            } label: {
                Text("Request \(viewModel.rideType.displayName)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.destinationCoordinate == nil || viewModel.route == nil || viewModel.isBooking)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.horizontal)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
#endif