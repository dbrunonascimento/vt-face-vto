//
//  FaceVTOEventEmitter.swift
//  VtFacevto
//
//  Created by Muhammad Syahman on 20/04/2020.
//  Copyright © 2020 Vettons. All rights reserved.
//

import Foundation

@objc(FaceVTOEvent)
open class FaceVTOEventEmitter: RCTEventEmitter {
  
  override init() {
    super.init()
    RNEventEmitter.sharedInstance.registerEventEmitter(eventEmitter: self)
  }
  
  /// Base overide for RCTEventEmitter.
  ///
  /// - Returns: all supported events
  @objc open override func supportedEvents() -> [String] {
    return RNEventEmitter.sharedInstance.allEvents
  }
  
    override public static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
}

class RNEventEmitter {

/// Shared Instance.
public static var sharedInstance = RNEventEmitter()

// ReactNativeEventEmitter is instantiated by React Native with the bridge.
private static var eventEmitter: FaceVTOEventEmitter!

private init() {}

// When React Native instantiates the emitter it is registered here.
func registerEventEmitter(eventEmitter: FaceVTOEventEmitter) {
  RNEventEmitter.eventEmitter = eventEmitter
}

func dispatch(name: String, body: Any?) {
  RNEventEmitter.eventEmitter.sendEvent(withName: name, body: body)
}

/// All Events which must be support by React Native.
lazy var allEvents: [String] = {
  var allEventNames: [String] = []
  
  // Append all events here
  allEventNames.append("onPress")
  allEventNames.append("error")
  
  return allEventNames
}()

}
