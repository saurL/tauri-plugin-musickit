// Copyright 2019-2023 Tauri Programme within The Commons Conservancy
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: MIT

import Foundation
import Tauri
import UIKit
import WebKit
import MusicKit
import MediaPlayer

struct TokenArgs: Decodable {
    let token: String
}

struct SetQueueArgs: Decodable {
    let trackIds: [String]
    let startPlaying: Bool
    let startPosition: Int
}

@available(iOS 15.0, *)
@_cdecl("init_plugin_musickit")
func init_plugin_musickit() -> MusicKitPlugin {
    return MusicKitPlugin()
}

@available(iOS 15.0, *)
public class MusicKitPlugin: Plugin {
    public let player = MPMusicPlayerController.applicationMusicPlayer
    public var userToken: String? = nil
    public var developerToken: String? = nil
    private var timeObserver: Timer?

    override public init() {
        super.init()
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackStateDidChange), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNowPlayingItemDidChange), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        player.beginGeneratingPlaybackNotifications()
    }
    
    deinit {
        if timeObserver != nil {
            player.endGeneratingPlaybackNotifications()
        }
        NotificationCenter.default.removeObserver(self)
    }

    	@objc public func initialize(_ invoke: Invoke) {
		print("MusicKit Plugin: initialize called")
		invoke.resolve()
	}

    @objc func authorize(_ invoke: Invoke) {
        print("MusicKit Plugin: authorize called")
        print("MusicKit Plugin: developerToken is nil: \(self.developerToken == nil)")
        print("MusicKit Plugin: developerToken length: \(self.developerToken?.count ?? 0)")
        
        Task {
            print("MusicKit Plugin: Requesting MusicAuthorization...")
            let status = await MusicAuthorization.request()
            print("MusicKit Plugin: Authorization status: \(status.toString())")
            
            if status == .authorized {
                print("MusicKit Plugin: Authorization successful, fetching user token...")
                do {
                    if let developerToken = self.developerToken {
                        print("MusicKit Plugin: Using developer token with length: \(developerToken.count)")
                        let token = try await MusicUserTokenProvider().userToken(for: developerToken, options: MusicTokenRequestOptions())
                        print("MusicKit Plugin: User token acquired with length: \(token.count)")
                        self.userToken = token
                        print("MusicKit Plugin: User token stored successfully")
                    } else {
                        print("MusicKit Plugin: Developer token not set, rejecting...")
                        invoke.reject("Developer token not set.")
                        return
                    }
                } catch {
                    print("MusicKit Plugin: Error fetching music user token: \(error.localizedDescription)")
                    invoke.reject("Failed to fetch music user token: \(error.localizedDescription)")
                    return
                }
            } else {
                print("MusicKit Plugin: Authorization failed with status: \(status.toString())")
            }
            
            var result: [String: Any] = [
                "status": status.toString(),
            ]
            if(self.userToken != nil) {
                print("MusicKit Plugin: Including user token in result")
                result["token"] = self.userToken
            } else {
                print("MusicKit Plugin: No user token available for result")
            }
            
            print("MusicKit Plugin: Resolving authorize with result: \(result)")
            invoke.resolve(result)
        }
    }

    @objc public func isAuthorized(_ invoke: Invoke) {
        let result = ["isAuthorized": self.userToken != nil]
        invoke.resolve(result)
    }

    @objc public func setUserToken(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(TokenArgs.self)
            print("MusicKit Plugin: setUserToken called with token length: \(args.token.count)")
            print("MusicKit Plugin: setUserToken token preview: \(String(args.token.prefix(20)))...")
            self.userToken = args.token
            print("MusicKit Plugin: user token set successfully")
            print("MusicKit Plugin: userToken is now nil: \(self.userToken == nil)")
            print("MusicKit Plugin: userToken length after set: \(self.userToken?.count ?? 0)")
            invoke.resolve()
        } catch {
            print("MusicKit Plugin: Error in setUserToken: \(error.localizedDescription)")
            invoke.reject("Failed to parse arguments: \(error.localizedDescription)")
        }
    }

    @objc public func unauthorize(_ invoke: Invoke) {
        self.userToken = nil
    }
  
      @objc public func getUserToken(_ invoke: Invoke) {
    print("MusicKit Plugin: getUserToken called.")
    print("MusicKit Plugin: userToken is nil: \(self.userToken == nil)")
    print("MusicKit Plugin: userToken value: \(self.userToken ?? "nil")")
    print("MusicKit Plugin: userToken length: \(self.userToken?.count ?? 0)")
    // Return the token directly as a string to match frontend expectations
    invoke.resolve(self.userToken ?? "")
  }
  
  @objc public func getDeveloperToken(_ invoke: Invoke) {
    print("MusicKit Plugin: getDeveloperToken called (minimal version)")
    invoke.resolve("")
  }
  
  @objc public func setDeveloperToken(_ invoke: Invoke) {
    do {
        let args = try invoke.parseArgs(TokenArgs.self)
        self.developerToken = args.token
        print("MusicKit Plugin: developer token set.")
        invoke.resolve()
    } catch {
        invoke.reject("Failed to parse arguments: \(error.localizedDescription)")
    }
  }
  
  @objc public func getStorefrontId(_ invoke: Invoke) {
    print("MusicKit Plugin: getStorefrontId called (minimal version)")
    invoke.resolve("")
  }
  
  @objc public func getStorefront(_ invoke: Invoke) {
    print("MusicKit Plugin: getStorefront called (minimal version)")
    invoke.resolve("")
  }
  
  @objc public func getAuthorizationStatus(_ invoke: Invoke) {
    print("MusicKit Plugin: getAuthorizationStatus called")
    let status = self.userToken != nil ? "authorized" : "notAuthorized"
    invoke.resolve(["status": status])
  }
  
  @objc public func setStorefront(_ invoke: Invoke) {
    print("MusicKit Plugin: setStorefront called (minimal version)")
    invoke.resolve()
  }
  
  @objc public func getQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: getQueue called (minimal version)")
    let result: [String: Any] = [
      "tracks": [],
      "currentTrackIndex": -1
    ]
    invoke.resolve(result)
  }
  
  @objc public func play(_ invoke: Invoke) {
    player.play()
    invoke.resolve()
  }
  
  @objc public func pause(_ invoke: Invoke) {
    player.pause()
    invoke.resolve()
  }
  
  @objc public func stop(_ invoke: Invoke) {
    player.stop()
    invoke.resolve()
  }
  
  @objc public func seek(_ invoke: Invoke) {
    print("MusicKit Plugin: seek called (minimal version)")
    invoke.resolve()
  }
  
  @objc public func next(_ invoke: Invoke) {
    player.skipToNextItem()
    invoke.resolve()
  }
  
  @objc public func previous(_ invoke: Invoke) {
    player.skipToPreviousItem()
    invoke.resolve()
  }
  
  @objc public func skipToItem(_ invoke: Invoke) {
    print("MusicKit Plugin: skipToItem called (minimal version)")
    invoke.resolve()
  }
  
  @objc public func setVolume(_ invoke: Invoke) {
    print("MusicKit Plugin: setVolume called (minimal version)")
    invoke.resolve()
  }

    @objc public func setQueue(_ invoke: Invoke) {
        print("MusicKit Plugin: setQueue called")
        do {
            let args = try invoke.parseArgs(SetQueueArgs.self)
            print("MusicKit Plugin: setQueue args - trackIds: \(args.trackIds), startPlaying: \(args.startPlaying), startPosition: \(args.startPosition)")
            
            // Validate track IDs - they should be valid Apple Music store IDs
            let validTrackIds = args.trackIds.filter { !$0.isEmpty }
            if validTrackIds.isEmpty {
                print("MusicKit Plugin: No valid track IDs provided")
                invoke.resolve(["success": false, "error": "No valid track IDs provided"])
                return
            }
            
            print("MusicKit Plugin: Creating queue with \(validTrackIds.count) tracks")
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            
            if args.startPosition > 0 && args.startPosition < validTrackIds.count {
                queue.startItemID = validTrackIds[args.startPosition]
                print("MusicKit Plugin: Setting start item ID to: \(validTrackIds[args.startPosition])")
            }
            
            print("MusicKit Plugin: Setting queue on player")
            player.setQueue(with: queue)
            
            if args.startPlaying {
                print("MusicKit Plugin: Starting playback")
                player.play()
            }
            
            print("MusicKit Plugin: setQueue completed successfully")
            invoke.resolve(["success": true, "error": ""])
        } catch {
            print("MusicKit Plugin: setQueue error: \(error.localizedDescription)")
            invoke.reject("Failed to set queue: \(error.localizedDescription)")
        }
    }
  
  @objc public func updateQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: updateQueue called (minimal version)")
    let result: [String: Any] = [
      "success": true,
      "error": ""
    ]
    invoke.resolve(result)
  }
  
  @objc public func appendToQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: appendToQueue called (minimal version)")
    let result: [String: Any] = [
      "success": true,
      "error": ""
    ]
    invoke.resolve(result)
  }
  
  @objc public func removeFromQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: removeFromQueue called (minimal version)")
    let result: [String: Any] = [
      "success": true,
      "error": ""
    ]
    invoke.resolve(result)
  }
  
  @objc public func insertTrackAtPosition(_ invoke: Invoke) {
    print("MusicKit Plugin: insertTrackAtPosition called")
    // This is a placeholder implementation.
    // A full implementation would require parsing track and position arguments
    // and using them with the MusicKit player queue.
    let result: [String: Any] = [
      "success": false,
      "error": "Not implemented"
    ]
    invoke.resolve(result)
  }
  
  @objc public func removeTrackAtPosition(_ invoke: Invoke) {
    print("MusicKit Plugin: removeTrackAtPosition called (minimal version)")
    let result: [String: Any] = [
      "success": true,
      "error": ""
    ]
    invoke.resolve(result)
  }
  
  @objc public func clearQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: clearQueue called (minimal version)")
    let result: [String: Any] = [
      "success": true,
      "error": ""
    ]
    invoke.resolve(result)
  }
  
  @objc public func getCurrentTrack(_ invoke: Invoke) {
    print("MusicKit Plugin: getCurrentTrack called (minimal version)")
    invoke.resolve("")
  }
  
  @objc public func getCurrentTrackInfo(_ invoke: Invoke) {
    print("MusicKit Plugin: getCurrentTrackInfo called (minimal version)")
    let result: [String: Any] = [
      "currentTrack": "",
      "currentTrackIndex": -1
    ]
    invoke.resolve(result)
  }
  
  @objc public func getPlaybackState(_ invoke: Invoke) {
    print("MusicKit Plugin: getPlaybackState called")
    
    let currentItem = player.nowPlayingItem
    let currentTime = player.currentPlaybackTime
    let duration = currentItem?.playbackDuration ?? 0.0
    let playbackState = player.playbackState
    
    let isPlaying = playbackState == .playing
    let isPaused = playbackState == .paused
    
    // Calculate progress (0-1)
    let progress = duration > 0 ? currentTime / duration : 0.0
    
    var trackData: [String: Any]? = nil
    if let item = currentItem {
        trackData = [
            "id": item.playbackStoreID,
            "title": item.title ?? "",
            "artistName": item.artist ?? "",  // camelCase to match frontend
            "albumName": item.albumTitle ?? "",  // camelCase to match frontend
            "genreNames": item.genre ?? "",
            "durationInMillis": Int(duration * 1000)  // camelCase to match frontend
        ]
    }
    
    let result: [String: Any] = [
        "playing": isPlaying,
        "paused": isPaused,
        "currentTrack": trackData as Any,
        "currentTime": currentTime,
        "duration": duration,
        "progress": progress,  // Add progress calculation
        "queuePosition": 0, // MPMusicPlayerController doesn't expose queue position easily
        "shuffleMode": "off", // MPMusicPlayerController doesn't expose shuffle mode easily
        "repeatMode": "none", // MPMusicPlayerController doesn't expose repeat mode easily
        "volume": 1.0 // Use default volume since player.volume is unavailable in iOS
    ]
    
    print("MusicKit Plugin: getPlaybackState result:", result)
    invoke.resolve(result)
  }

    @objc func handlePlaybackStateDidChange(notification: NSNotification) {
        print("MusicKit Plugin: handlePlaybackStateDidChange called")
        print("MusicKit Plugin: Current playback state: \(player.playbackState.toString())")
        let data: [String: JSValue] = [
            "state": player.playbackState.toString() as JSValue
        ]
        print("MusicKit Plugin: Triggering musickit-playback-state-changed")
        trigger("musickit-playback-state-changed", data: data)
        
        if player.playbackState == .playing {
            print("MusicKit Plugin: Starting time observer")
            startTimeObserver()
        } else {
            print("MusicKit Plugin: Stopping time observer")
            stopTimeObserver()
        }
    }

    @objc func handleNowPlayingItemDidChange(notification: NSNotification) {
        print("MusicKit Plugin: handleNowPlayingItemDidChange called")
        let trackData = itemToTrack(player.nowPlayingItem) ?? [:]
        print("MusicKit Plugin: Track data: \(trackData)")
        print("MusicKit Plugin: Triggering musickit-track-changed")
        trigger("musickit-track-changed", data: [
            "track": trackData
        ])
    }

    private func itemToTrack(_ item: MPMediaItem?) -> [String: JSValue]? {
        guard let item = item else {
            return nil
        }

        return [
            "id": item.playbackStoreID as JSValue,
            "title": (item.title ?? "") as JSValue,
            "artistName": (item.artist ?? "") as JSValue,
            "albumName": (item.albumTitle ?? "") as JSValue,
            "genreNames": (item.genre ?? "") as JSValue,
            "durationInMillis": Int(item.playbackDuration * 1000) as JSValue
        ]
    }
    
    private func startTimeObserver() {
        print("MusicKit Plugin: startTimeObserver called")
        guard timeObserver == nil else { 
            print("MusicKit Plugin: Time observer already exists, skipping")
            return 
        }
        print("MusicKit Plugin: Creating new time observer")
        timeObserver = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentTime = self.player.currentPlaybackTime
            print("MusicKit Plugin: Time observer tick - current time: \(currentTime)")
            self.trigger("musickit-playback-time-changed", data: ["currentTime": currentTime as JSValue])
        }
        print("MusicKit Plugin: Time observer started successfully")
    }

    private func stopTimeObserver() {
        print("MusicKit Plugin: stopTimeObserver called")
        guard let observer = timeObserver else { 
            print("MusicKit Plugin: No time observer to stop")
            return 
        }
        print("MusicKit Plugin: Stopping time observer")
        observer.invalidate()
        timeObserver = nil
        print("MusicKit Plugin: Time observer stopped")
    }
    
    @objc func registerListener(_ invoke: Invoke) {
        print("MusicKit Plugin: registerListener called")
        invoke.resolve()
    }
}

extension MPMusicPlaybackState {
    func toString() -> String {
        switch self {
        case .stopped: return "stopped"
        case .playing: return "playing"
        case .paused: return "paused"
        case .interrupted: return "interrupted"
        case .seekingForward: return "seekingForward"
        case .seekingBackward: return "seekingBackward"
        @unknown default: return "unknown"
        }
    }
}

@available(iOS 15.0, *)
extension MusicAuthorization.Status {
    func toString() -> String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .authorized: return "authorized"
        @unknown default: return "unknown"
        }
    }
} 