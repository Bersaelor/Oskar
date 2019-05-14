//
//  LoadPlist.swift
//  LooC AR
//
//  Created by Konrad Feiler on 09.03.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import Foundation

func loadPlist<T>(_ fileName: String, defaultValues: T) -> T where T: Decodable {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: ".plist"),
        let data = try? Data(contentsOf: url) else {
            print("WARNING: Couldn't find \(fileName).plist, falling back to Default")
            return defaultValues
    }
    do {
        return try PropertyListDecoder().decode(T.self, from: data)
    } catch {
        print("Failed to decode data from \(fileName).plist: \(error)")
        return defaultValues
    }
}
