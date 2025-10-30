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
        Store(name: "Net-a-Porter", url: "https://www.net-a-porter.com", category: .luxury),
        Store(name: "Nordstrom", url: "https://www.nordstrom.com", category: .luxury),
        Store(name: "Michael Kors", url: "https://www.michaelkors.com", category: .luxury),
        Store(name: "DKNY", url: "https://www.dkny.com", category: .luxury),

        // Fashion
        Store(name: "ASOS", url: "https://www.asos.com", category: .fashion),
        Store(name: "Revolve", url: "https://www.revolve.com", category: .fashion),
        Store(name: "H&M", url: "https://www.hm.com", category: .fashion),
        Store(name: "UNIQLO", url: "https://www.uniqlo.com", category: .fashion),
        Store(name: "Forever 21", url: "https://www.forever21.com", category: .fashion),
        Store(name: "Stradivarius", url: "https://www.stradivarius.com", category: .fashion),
        Store(name: "Urban Outfitters", url: "https://www.urbanoutfitters.com", category: .fashion),
        Store(name: "PrettyLittleThing", url: "https://www.prettylittlething.com", category: .fashion),
        Store(name: "BooHoo", url: "https://www.boohoo.com", category: .fashion),

        // Streetwear
        Store(name: "Shein", url: "https://www.shein.com", category: .streetwear),
        Store(name: "Guess", url: "https://www.guess.com", category: .streetwear),
        Store(name: "Superdry", url: "https://www.superdry.com", category: .streetwear),
        Store(name: "Levi's", url: "https://www.levi.com", category: .streetwear),

        // Athletic
        Store(name: "Adidas", url: "https://www.adidas.com", category: .athletic),
        Store(name: "Lululemon", url: "https://www.lululemon.com", category: .athletic),
        Store(name: "Vans", url: "https://www.vans.com", category: .athletic),

        // Sustainable
        Store(name: "Organic Basics", url: "https://www.organicbasics.com", category: .sustainable),
        Store(name: "Stitch Fix", url: "https://www.stitchfix.com", category: .sustainable),
        Store(name: "TOMS", url: "https://www.toms.com", category: .sustainable),
        Store(name: "Crocs", url: "https://www.crocs.com", category: .sustainable),
        Store(name: "End.", url: "https://www.endclothing.com", category: .fashion)
    ]
}
