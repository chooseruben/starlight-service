
import SwiftUI
import MapKit

struct AddressSearchView: View {
    @Binding var address: String

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search street address", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                if isSearching {
                    ProgressView()
                        .padding()
                }

                List {
                    ForEach(results, id: \.self) { item in
                        Button {
                            address = item.placemark.title
                                ?? item.name
                                ?? searchText
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Location")
                                        .fontWeight(.medium)

                                    Text(item.placemark.title ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task(id: searchText) {
                await searchAddresses()
            }
            .onAppear {
                searchFocused = true
            }
        }
    }

    private func searchAddresses() async {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard query.count >= 3 else {
            results = []
            isSearching = false
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(350))
            try Task.checkCancellation()

            isSearching = true

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query

            // Houston area is preferred, but not required.
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: 29.7604,
                    longitude: -95.3698
                ),
                latitudinalMeters: 200000,
                longitudinalMeters: 200000
            )

            let response = try await MKLocalSearch(
                request: request
            ).start()

            try Task.checkCancellation()
            results = response.mapItems
            isSearching = false

        } catch {
            if !Task.isCancelled {
                results = []
                isSearching = false
            }
        }
    }
}

#Preview {
    AddressSearchView(address: .constant(""))
}
