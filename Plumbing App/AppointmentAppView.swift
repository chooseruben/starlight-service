
import SwiftUI
import MapKit

struct AppointmentMapView: View {

    let address: String

    @State private var destination: MKMapItem?
    @State private var isSearching = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Button {
                openDirections()
            } label: {
                Label(address, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
            .disabled(destination == nil)

            if let destination {
                Button {
                    openDirections()
                } label: {
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: destination.placemark.coordinate,
                                latitudinalMeters: 700,
                                longitudinalMeters: 700
                            )
                        ),
                        interactionModes: []
                    ) {
                        Marker(
                            "Job Location",
                            coordinate: destination.placemark.coordinate
                        )
                    }
                    .frame(height: 160)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                    .allowsHitTesting(false)
                }
                .buttonStyle(.plain)

                Button {
                    openDirections()
                } label: {
                    Label(
                        "Get Driving Directions",
                        systemImage: "car.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }

            } else if isSearching {
                ProgressView("Finding location...")
                    .frame(maxWidth: .infinity)
                    .padding()

            } else {
                Text("Location not found. Check the address.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .task(id: address) {
            await findLocation()
        }
    }

    private func findLocation() async {
        isSearching = true
        destination = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address

        do {
            let response = try await MKLocalSearch(
                request: request
            ).start()

            destination = response.mapItems.first
        } catch {
            destination = nil
        }

        isSearching = false
    }

    private func openDirections() {
        guard let destination else { return }

        destination.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
}

#Preview {
    AppointmentMapView(
        address: "Houston City Hall, Houston, TX"
    )
}
