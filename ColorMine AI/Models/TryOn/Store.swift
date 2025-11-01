//
//  Store.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation

struct Store: Identifiable, Codable {
    let id: UUID
    let name: String
    let url: String             // Affiliate URL
    let category: StoreCategory
    let logoImageName: String?  // Optional SF Symbol or asset name

    init(
        id: UUID = UUID(),
        name: String,
        url: String,
        category: StoreCategory = .fashion,
        logoImageName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.category = category
        self.logoImageName = logoImageName
    }
}

enum StoreCategory: String, Codable {
    case luxury = "Luxury"
    case fashion = "Fashion"
    case streetwear = "Streetwear"
    case athletic = "Athletic"
    case sustainable = "Sustainable"
}

// MARK: - Predefined Stores
extension Store {
    static let predefinedStores: [Store] = [
        // Luxury
        Store(name: "Net-a-Porter", url: "https://www.net-a-porter.com", category: .luxury, logoImageName: "Net-a-Porter-logo"),
        Store(name: "Nordstrom", url: "https://www.nordstrom.com", category: .luxury, logoImageName: "Nordstrom-logo"),
        Store(name: "Michael Kors", url: "https://www.michaelkors.com", category: .luxury, logoImageName: "Michael-Kors-logo"),
        Store(name: "DKNY", url: "https://www.dkny.com", category: .luxury, logoImageName: "DKNY-logo"),

        // Fashion
        Store(name: "ASOS", url: "https://www.asos.com", category: .fashion, logoImageName: "Asos-logo"),
        Store(name: "Revolve", url: "https://www.revolve.com", category: .fashion, logoImageName: "Revolve-logo"),
        Store(name: "H&M", url: "https://www.hm.com", category: .fashion, logoImageName: "H&M-logo"),
        Store(name: "UNIQLO", url: "https://www.uniqlo.com", category: .fashion, logoImageName: "Uniqlo-Logo"),
        Store(name: "Forever 21", url: "https://www.forever21.com", category: .fashion, logoImageName: "Forever-21-logo"),
        Store(name: "Stradivarius", url: "https://www.stradivarius.com", category: .fashion, logoImageName: "Stradivarius-logo"),
        Store(name: "Urban Outfitters", url: "https://www.urbanoutfitters.com", category: .fashion, logoImageName: "Urban-Outfitters-Logo"),
        Store(name: "PrettyLittleThing", url: "https://www.prettylittlething.com", category: .fashion, logoImageName: "Pretty Little Thing-logo"),
        Store(name: "BooHoo", url: "https://www.boohoo.com", category: .fashion, logoImageName: "Boohoo-logo"),

        // Streetwear
        Store(name: "Shein", url: "https://www.shein.com", category: .streetwear, logoImageName: "Shein-logo"),
        Store(name: "Guess", url: "https://www.guess.com", category: .streetwear, logoImageName: "Guess-logo"),
        Store(name: "Superdry", url: "https://www.superdry.com", category: .streetwear, logoImageName: "Superdry-logo"),
        Store(name: "Levi's", url: "https://www.levi.com", category: .streetwear, logoImageName: "Levi's-logo"),

        // Athletic
        Store(name: "Adidas", url: "https://www.adidas.com", category: .athletic, logoImageName: "Adidas-logo"),
        Store(name: "Lululemon", url: "https://www.lululemon.com", category: .athletic, logoImageName: "Lululemon-logo"),
        Store(name: "Vans", url: "https://www.vans.com", category: .athletic, logoImageName: "vans-logo"),

        // Sustainable
        Store(name: "Organic Basics", url: "https://www.organicbasics.com", category: .sustainable, logoImageName: "Organic Basics-logo"),
        Store(name: "Stitch Fix", url: "https://www.stitchfix.com", category: .sustainable, logoImageName: "Stitch-Fix-logo"),
        Store(name: "TOMS", url: "https://www.toms.com", category: .sustainable, logoImageName: "TOMS logo"),
        Store(name: "Crocs", url: "https://www.crocs.com", category: .sustainable, logoImageName: "Crocs-logo"),
        Store(name: "End.", url: "https://www.endclothing.com", category: .fashion, logoImageName: "END-logo")
    ]
}
