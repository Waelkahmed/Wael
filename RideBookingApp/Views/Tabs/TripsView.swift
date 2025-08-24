import SwiftUI

struct TripsView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        List {
            ForEach(session.tripStore.trips) { trip in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(trip.pickupName) → \(trip.dropoffName)").bold()
                        Spacer()
                        Text(trip.fare, format: .currency(code: Locale.current.currency?.identifier ?? "USD")).bold()
                    }
                    Text("\(trip.startDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        if let rating = trip.rating {
                            Text("Rating: \(rating)★").font(.caption)
                        } else {
                            Button("Rate 5★") { session.tripStore.rateTrip(id: trip.id, rating: 5) }
                                .buttonStyle(.bordered)
                                .font(.caption)
                        }
                        if trip.status != .canceled {
                            Button("Cancel") { session.tripStore.cancelTrip(id: trip.id) }
                                .buttonStyle(.bordered)
                                .font(.caption)
                        } else {
                            Text("Canceled").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Trips")
    }
}