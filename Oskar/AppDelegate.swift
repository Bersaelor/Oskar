//
//  AppDelegate.swift
//  Oskar
//
//  Created by Konrad Feiler on 14.05.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import UIKit
import SwiftyBeaver

let log = SwiftyBeaver.self
let oniPad = UIDevice.current.userInterfaceIdiom == .pad
let isDebugging = ProcessInfo.processInfo.environment["debugger"] == "true"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        startCrashLogging()

        return true
    }

    private func startCrashLogging() {
        let console = ConsoleDestination()  // log to Xcode Console
        
        //        // use custom format and set console output to short time, log level & message
        console.format = "$DHH:mm:ss.SSS$d $N.$F:$l $C$L$c: $M"
        
        #if DEBUG
        console.minLevel = SwiftyBeaver.Level.debug
        #else
        console.minLevel = SwiftyBeaver.Level.error
        #endif
        
        // add the destinations to SwiftyBeaver
        log.addDestination(console)
    }

}

