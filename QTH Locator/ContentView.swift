//
//  ContentView.swift
//  QTH Locator
//
//  Created by Mateusz Hajder on 01/04/2024.
//

import CoreLocation
import Foundation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        DispatchQueue.main.async {
            self.location = currentLocation.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.location = nil
        }
    }
}

func toMaiden(Latitude lat: Double, Longitude lon: Double? = nil, Precision precision: Int = 5) -> String {
    let A = Int(("A" as UnicodeScalar).value)
    var lon = lon ?? 0.0
    var a = divmod(lon + 180, 20)
    var b = divmod(lat + 90, 10)
    var maiden = String(UnicodeScalar(A + Int(a.quotient))!) + String(UnicodeScalar(A + Int(b.quotient))!)
    lon = a.remainder / 2.0
    var lat = b.remainder
    var i = 1
    
    while i < precision {
        i += 1
        a = divmod(lon, 1)
        b = divmod(lat, 1)
        if i % 2 == 0 {
            maiden += String(Int(a.quotient)) + String(Int(b.quotient))
            lon = 24 * a.remainder
            lat = 24 * b.remainder
        } else {
            maiden += String(UnicodeScalar(A + Int(a.quotient))!) + String(UnicodeScalar(A + Int(b.quotient))!)
            lon = 10 * a.remainder
            lat = 10 * b.remainder
        }
    }

    return maiden
}

func divmod(_ numerator: Double, _ denominator: Double) -> (quotient: Double, remainder: Double) {
    let quotient = (numerator / denominator).rounded(.towardZero)
    let remainder = numerator.truncatingRemainder(dividingBy: denominator)

    return (quotient, remainder)
}

func coloredMaidenText(maiden: String) -> Text {
    var coloredText: Text = Text("")
    let colors: [Color] = [.red, .green, .blue, .orange, .purple]
    var colorIndex = 0

    for index in stride(from: 0, to: maiden.count, by: 2) {
        let startIndex = maiden.index(maiden.startIndex, offsetBy: index)
        let endIndex = maiden.index(startIndex, offsetBy: 2)
        let pair = maiden[startIndex..<endIndex]
        coloredText = coloredText + Text(String(pair)).foregroundColor(colors[colorIndex % colors.count])
        colorIndex += 1
    }

    return coloredText
}

struct ContentView: View {
    @ObservedObject var locationManager = LocationManager()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let location = locationManager.location {
                    
                    coloredMaidenText(maiden: toMaiden(Latitude: location.latitude, Longitude: location.longitude))
                        .font(.system(size: 24))
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.8, alignment: .center)
                    
                    Spacer()

                    Text("Lat: \(location.latitude)\nLong: \(location.longitude)")
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width)
                        .padding(.bottom)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No location data available")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
