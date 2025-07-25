// Copyright 2019-2023 Tauri Programme within The Commons Conservancy
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: MIT

import Foundation
import Tauri
import UIKit
import WebKit
import MusicKit
import MediaPlayer
import Combine

struct TokenArgs: Decodable {
    let token: String
}

struct SeekArgs: Decodable {
    let time: Double
}

struct SkipToItemArgs: Decodable {
    let trackId: String
    let startPlaying: Bool
}

struct SetVolumeArgs: Decodable {
    let volume: Double
}

struct RemoveTrackAtPositionArgs: Decodable {
    let position: Int
}

struct SetQueueArgs: Decodable {
    let tracks: [FullTrackData]
    let startPlaying: Bool
    let startPosition: Int
}

struct UpdateQueueArgs: Decodable {
    let tracks: [FullTrackData]
}

struct InsertTrackArgs: Decodable {
    let track: FullTrackData
    let position: Int
}

struct InsertTracksArgs: Decodable {
    let tracks: [FullTrackData]
    let position: Int
}

struct RemoveTrackArgs: Decodable {
    let trackId: String
}

struct AppendTracksArgs: Decodable {
    let tracks: [FullTrackData]
}

struct FullTrackData: Codable {
    let id: String
    let title: String
    let artistName: String
    let albumName: String
    let genreNames: String
    let artwork: String
    let durationInMillis: Int
    let isExplicit: Bool
    let isPlayable: Bool
}

// Queue Manager for better queue management
class QueueManager {
    static let shared = QueueManager()
    
    private var queue: [FullTrackData] = [] {
        didSet {
            queuePublisher.send(queue)
        }
    }
    
    private var queuePublisher = PassthroughSubject<[FullTrackData], Never>()
    
    private init() {}
    
    func updateQueue(with tracks: [FullTrackData]) {
        queue = tracks
    }
    
    func findTrack(byId id: String) -> FullTrackData? {
        return queue.first { $0.id == id }
    }
    
    func clearQueue() {
        queue.removeAll()
    }
    
    func getQueue() -> [FullTrackData] {
        return queue
    }
    
    var publisher: AnyPublisher<[FullTrackData], Never> {
        return queuePublisher.eraseToAnyPublisher()
    }
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
    private var cancellables: Set<AnyCancellable> = []
    private var debounceTimer: Timer?
    
    // Queue management
    private let queueManager = QueueManager.shared
    
    override public init() {
        super.init()
        setupObservers()
        setupAppLifecycleObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackStateDidChange), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNowPlayingItemDidChange), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        player.beginGeneratingPlaybackNotifications()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // Sync queue if player queue is empty but we have tracks in our queue manager
        if player.nowPlayingItem == nil {
            let queue = queueManager.getQueue()
            if !queue.isEmpty {
                print("MusicKit Plugin: Queue is empty, syncing with local queue copy.")
                let storeIDs = queue.map { $0.id }
                let queueDescriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: storeIDs)
                player.setQueue(with: queueDescriptor)
                player.prepareToPlay()
            }
        }
    }
    
    deinit {
        if timeObserver != nil {
            player.endGeneratingPlaybackNotifications()
        }
        NotificationCenter.default.removeObserver(self)
        cancellables.forEach { $0.cancel() }
        debounceTimer?.invalidate()
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
    print("MusicKit Plugin: getQueue called")
    
    let queue = queueManager.getQueue()
    let currentTrackIndex = player.indexOfNowPlayingItem
    
    let result: [String: Any] = [
      "items": queue.map { track in
        [
          "id": track.id,
          "title": track.title,
          "artist": track.artistName,
          "album": track.albumName,
          "duration": Double(track.durationInMillis) / 1000.0,
          "artworkUrl": track.artwork,
          "isExplicit": track.isExplicit,
          "isPlayable": track.isPlayable
        ]
      },
      "position": currentTrackIndex
    ]
    
    print("MusicKit Plugin: getQueue returning \(queue.count) tracks, position: \(currentTrackIndex)")
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
    print("MusicKit Plugin: seek called")
    
    // Parse the time argument using the proper method
    do {
        let args = try invoke.parseArgs(SeekArgs.self)
        let time = args.time
        print("MusicKit Plugin: Seeking to time: \(time)")
        
        // Use MPMusicPlayerController's seek functionality
        player.currentPlaybackTime = time
        invoke.resolve()
    } catch {
        invoke.reject("Invalid arguments for seek: \(error.localizedDescription)")
    }
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
    print("MusicKit Plugin: skipToItem called")
    
    // Parse arguments using the proper method
    do {
        let args = try invoke.parseArgs(SkipToItemArgs.self)
        let trackId = args.trackId
        let startPlaying = args.startPlaying
        print("MusicKit Plugin: Skipping to track: \(trackId), startPlaying: \(startPlaying)")
        
        // Find the track in our queue manager
        if queueManager.findTrack(byId: trackId) != nil {
            // Find the position of this track in the current queue
            let queue = queueManager.getQueue()
            if let position = queue.firstIndex(where: { $0.id == trackId }) {
                // Create a queue descriptor with the specific track
                let queueDescriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [trackId])
                player.setQueue(with: queueDescriptor)
                
                if startPlaying {
                    player.play()
                }
                
                print("MusicKit Plugin: Successfully skipped to track at position: \(position)")
                invoke.resolve()
            } else {
                invoke.reject("Track not found in queue")
            }
        } else {
            invoke.reject("Track not found")
        }
    } catch {
        invoke.reject("Invalid arguments for skipToItem: \(error.localizedDescription)")
    }
  }
  
  @objc public func setVolume(_ invoke: Invoke) {
    print("MusicKit Plugin: setVolume called")
    
    // Parse the volume argument using the proper method
    do {
        let args = try invoke.parseArgs(SetVolumeArgs.self)
        let volume = args.volume
        print("MusicKit Plugin: Setting volume to: \(volume)")
        
        // Note: iOS doesn't allow direct volume control through MPMusicPlayerController
        // This is a stub implementation as volume control is handled by the system
        // The volume parameter is ignored and system volume controls should be used instead
        
        invoke.resolve()
    } catch {
        invoke.reject("Invalid arguments for setVolume: \(error.localizedDescription)")
    }
  }

    @objc public func setQueue(_ invoke: Invoke) {
        print("MusicKit Plugin: setQueue called")
        do {
            let args = try invoke.parseArgs(SetQueueArgs.self)
            print("MusicKit Plugin: setQueue args - tracks: \(args.tracks.count), startPlaying: \(args.startPlaying), startPosition: \(args.startPosition)")
            
            // Store full track objects in shadow queue
            self.queueManager.updateQueue(with: args.tracks)
            
            // Extract track IDs for MediaPlayer queue
            let trackIds = args.tracks.map { $0.id }
            let validTrackIds = trackIds.filter { !$0.isEmpty }
            
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
    print("MusicKit Plugin: updateQueue called")
    do {
        let args = try invoke.parseArgs(UpdateQueueArgs.self)
        print("MusicKit Plugin: updateQueue args - tracks: \(args.tracks.count)")
        
        // Update the shadow queue
        queueManager.updateQueue(with: args.tracks)
        
        // Update the MediaPlayer queue
        let trackIds = args.tracks.map { $0.id }
        let validTrackIds = trackIds.filter { !$0.isEmpty }
        
        if !validTrackIds.isEmpty {
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            player.setQueue(with: queue)
            print("MusicKit Plugin: Queue updated with \(validTrackIds.count) tracks")
        }
        
        invoke.resolve(["success": true, "error": ""])
    } catch {
        print("MusicKit Plugin: updateQueue error: \(error.localizedDescription)")
        invoke.reject("Failed to update queue: \(error.localizedDescription)")
    }
  }
  
  @objc public func appendTracksToQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: appendTracksToQueue called")
    do {
        let args = try invoke.parseArgs(AppendTracksArgs.self)
        print("MusicKit Plugin: appendTracksToQueue args - tracks: \(args.tracks.count)")
        
        // Get current queue and append new tracks
        var currentQueue = queueManager.getQueue()
        currentQueue.append(contentsOf: args.tracks)
        queueManager.updateQueue(with: currentQueue)
        
        // Update MediaPlayer queue
        let trackIds = currentQueue.map { $0.id }
        let validTrackIds = trackIds.filter { !$0.isEmpty }
        
        if !validTrackIds.isEmpty {
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            player.setQueue(with: queue)
            print("MusicKit Plugin: Appended \(args.tracks.count) tracks to queue")
        }
        
        invoke.resolve(["success": true, "error": ""])
    } catch {
        print("MusicKit Plugin: appendTracksToQueue error: \(error.localizedDescription)")
        invoke.reject("Failed to append tracks: \(error.localizedDescription)")
    }
  }
  
  @objc public func removeTrackFromQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: removeTrackFromQueue called")
    do {
        let args = try invoke.parseArgs(RemoveTrackArgs.self)
        print("MusicKit Plugin: removeTrackFromQueue args - trackId: \(args.trackId)")
        
        // Get current queue and remove the track
        var currentQueue = queueManager.getQueue()
        currentQueue.removeAll { $0.id == args.trackId }
        queueManager.updateQueue(with: currentQueue)
        
        // Update MediaPlayer queue
        let trackIds = currentQueue.map { $0.id }
        let validTrackIds = trackIds.filter { !$0.isEmpty }
        
        if !validTrackIds.isEmpty {
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            player.setQueue(with: queue)
            print("MusicKit Plugin: Removed track from queue")
        }
        
        invoke.resolve(["success": true, "error": ""])
    } catch {
        print("MusicKit Plugin: removeTrackFromQueue error: \(error.localizedDescription)")
        invoke.reject("Failed to remove track: \(error.localizedDescription)")
    }
  }
  
  @objc public func insertTrackAtPosition(_ invoke: Invoke) {
    print("MusicKit Plugin: insertTrackAtPosition called")
    do {
        let args = try invoke.parseArgs(InsertTrackArgs.self)
        print("MusicKit Plugin: insertTrackAtPosition args - track: \(args.track.title), position: \(args.position)")
        
        // Get current queue and insert the track
        var currentQueue = queueManager.getQueue()
        let insertIndex = min(args.position, currentQueue.count)
        currentQueue.insert(args.track, at: insertIndex)
        queueManager.updateQueue(with: currentQueue)
        
        // Update MediaPlayer queue
        let trackIds = currentQueue.map { $0.id }
        let validTrackIds = trackIds.filter { !$0.isEmpty }
        
        if !validTrackIds.isEmpty {
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            player.setQueue(with: queue)
            print("MusicKit Plugin: Inserted track at position \(insertIndex)")
        }
        
        invoke.resolve(["success": true, "error": ""])
    } catch {
        print("MusicKit Plugin: insertTrackAtPosition error: \(error.localizedDescription)")
        invoke.reject("Failed to insert track: \(error.localizedDescription)")
    }
  }
  
  @objc public func insertTracksAtPosition(_ invoke: Invoke) {
    print("MusicKit Plugin: insertTracksAtPosition called")
    do {
        let args = try invoke.parseArgs(InsertTracksArgs.self)
        print("MusicKit Plugin: insertTracksAtPosition args - tracks: \(args.tracks.count), position: \(args.position)")
        
        // Get current queue and insert the tracks
        var currentQueue = queueManager.getQueue()
        let insertIndex = min(args.position, currentQueue.count)
        currentQueue.insert(contentsOf: args.tracks, at: insertIndex)
        queueManager.updateQueue(with: currentQueue)
        
        // Update MediaPlayer queue
        let trackIds = currentQueue.map { $0.id }
        let validTrackIds = trackIds.filter { !$0.isEmpty }
        
        if !validTrackIds.isEmpty {
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            player.setQueue(with: queue)
            print("MusicKit Plugin: Inserted \(args.tracks.count) tracks at position \(insertIndex)")
        }
        
        invoke.resolve(["success": true, "error": ""])
    } catch {
        print("MusicKit Plugin: insertTracksAtPosition error: \(error.localizedDescription)")
        invoke.reject("Failed to insert tracks: \(error.localizedDescription)")
    }
  }
  
  @objc public func removeTrackAtPosition(_ invoke: Invoke) {
    print("MusicKit Plugin: removeTrackAtPosition called")
    do {
        let args = try invoke.parseArgs(RemoveTrackAtPositionArgs.self)
        let position = args.position
        print("MusicKit Plugin: removeTrackAtPosition args - position: \(position)")
        
        // Get current queue and remove the track at the specified position
        var currentQueue = queueManager.getQueue()
        if position >= 0 && position < currentQueue.count {
            currentQueue.remove(at: position)
            queueManager.updateQueue(with: currentQueue)
            
            // Update MediaPlayer queue
            let trackIds = currentQueue.map { $0.id }
            let validTrackIds = trackIds.filter { !$0.isEmpty }
            
            if !validTrackIds.isEmpty {
                let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
                player.setQueue(with: queue)
                print("MusicKit Plugin: Removed track at position \(position)")
            }
            
            invoke.resolve(["success": true, "error": ""])
        } else {
            invoke.reject("Invalid position: \(position)")
        }
    } catch {
        print("MusicKit Plugin: removeTrackAtPosition error: \(error.localizedDescription)")
        invoke.reject("Failed to remove track at position: \(error.localizedDescription)")
    }
  }
  
  @objc public func clearQueue(_ invoke: Invoke) {
    print("MusicKit Plugin: clearQueue called")
    
    // Clear the shadow queue
    queueManager.clearQueue()
    
    // Clear the MediaPlayer queue by setting an empty queue
    let emptyQueue = MPMusicPlayerStoreQueueDescriptor(storeIDs: [])
    player.setQueue(with: emptyQueue)
    
    print("MusicKit Plugin: Queue cleared successfully")
    invoke.resolve(["success": true, "error": ""])
  }
  
  @objc public func getCurrentTrack(_ invoke: Invoke) {
    print("MusicKit Plugin: getCurrentTrack called")
    
    guard let currentItem = player.nowPlayingItem else {
        invoke.resolve([:])
        return
    }
    
    let trackId = currentItem.playbackStoreID
    if let currentTrack = queueManager.findTrack(byId: trackId) {
        let result: [String: Any] = [
            "id": currentTrack.id,
            "title": currentTrack.title,
            "artist": currentTrack.artistName,
            "album": currentTrack.albumName,
            "duration": Double(currentTrack.durationInMillis) / 1000.0,
            "artworkUrl": currentTrack.artwork,
            "isExplicit": currentTrack.isExplicit,
            "isPlayable": currentTrack.isPlayable
        ]
        invoke.resolve(result)
    } else {
        // Fallback to MPMediaItem data
        let result: [String: Any] = [
            "id": currentItem.playbackStoreID,
            "title": currentItem.title ?? "",
            "artist": currentItem.artist ?? "",
            "album": currentItem.albumTitle ?? "",
            "duration": currentItem.playbackDuration,
            "artworkUrl": "",
            "isExplicit": false,
            "isPlayable": true
        ]
        invoke.resolve(result)
    }
  }
  
  @objc public func getCurrentTrackInfo(_ invoke: Invoke) {
    print("MusicKit Plugin: getCurrentTrackInfo called")
    
    guard let currentItem = player.nowPlayingItem else {
        let result: [String: Any] = [
            "currentTrack": [:] as [String: Any],
            "currentTrackIndex": -1
        ]
        invoke.resolve(result)
        return
    }
    
    let trackId = currentItem.playbackStoreID
    let currentTrackIndex = player.indexOfNowPlayingItem
    
    if let currentTrack = queueManager.findTrack(byId: trackId) {
        let trackInfo: [String: Any] = [
            "id": currentTrack.id,
            "title": currentTrack.title,
            "artist": currentTrack.artistName,
            "album": currentTrack.albumName,
            "duration": Double(currentTrack.durationInMillis) / 1000.0,
            "artworkUrl": currentTrack.artwork,
            "isExplicit": currentTrack.isExplicit,
            "isPlayable": currentTrack.isPlayable
        ]
        
        let result: [String: Any] = [
            "currentTrack": trackInfo,
            "currentTrackIndex": currentTrackIndex
        ]
        invoke.resolve(result)
    } else {
        // Fallback to MPMediaItem data
        let trackInfo: [String: Any] = [
            "id": currentItem.playbackStoreID,
            "title": currentItem.title ?? "",
            "artist": currentItem.artist ?? "",
            "album": currentItem.albumTitle ?? "",
            "duration": currentItem.playbackDuration,
            "artworkUrl": "",
            "isExplicit": false,
            "isPlayable": true
        ]
        
        let result: [String: Any] = [
            "currentTrack": trackInfo,
            "currentTrackIndex": currentTrackIndex
        ]
        invoke.resolve(result)
    }
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
        // Find the corresponding track in our shadow queue
        let trackId = item.playbackStoreID
        if let shadowTrack = queueManager.findTrack(byId: trackId) {
            // Use complete metadata from shadow queue
            trackData = [
                "id": shadowTrack.id,
                "title": shadowTrack.title,
                "artistName": shadowTrack.artistName,
                "albumName": shadowTrack.albumName,
                "genreNames": shadowTrack.genreNames,
                "durationInMillis": shadowTrack.durationInMillis,
                "artwork": shadowTrack.artwork
            ]
        } else {
            // Fallback to MPMediaItem data if not found in shadow queue
            trackData = [
                "id": item.playbackStoreID,
                "title": item.title ?? "",
                "artistName": item.artist ?? "",
                "albumName": item.albumTitle ?? "",
                "genreNames": item.genre ?? "",
                "durationInMillis": Int(duration * 1000)
            ]
        }
    }
    
    let result: [String: Any] = [
        "playing": isPlaying,
        "paused": isPaused,
        "currentTrack": trackData as Any,
        "currentTime": currentTime,
        "duration": duration,
        "progress": progress,  // Add progress calculation
        "queuePosition": player.indexOfNowPlayingItem, // Use actual queue position
        "shuffleMode": player.shuffleMode == .default ? "off" : "on", // Use actual shuffle mode
        "repeatMode": player.repeatMode == .default ? "none" : "all", // Use actual repeat mode
        "volume": 1.0 // Use default volume since player.volume is unavailable in iOS
    ]
    
    print("MusicKit Plugin: getPlaybackState result:", result)
    invoke.resolve(result)
  }

  @objc public func insertTrackNext(_ invoke: Invoke) {
    print("MusicKit Plugin: insertTrackNext called")
    do {
        let args = try invoke.parseArgs(InsertTrackArgs.self)
        print("MusicKit Plugin: insertTrackNext args - track: \(args.track.title)")
        
        // Get current queue and insert the track after the current position
        var currentQueue = queueManager.getQueue()
        let currentPosition = player.indexOfNowPlayingItem
        let insertIndex = min(currentPosition + 1, currentQueue.count)
        currentQueue.insert(args.track, at: insertIndex)
        queueManager.updateQueue(with: currentQueue)
        
        // Update MediaPlayer queue
        let trackIds = currentQueue.map { $0.id }
        let validTrackIds = trackIds.filter { !$0.isEmpty }
        
        if !validTrackIds.isEmpty {
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            player.setQueue(with: queue)
            print("MusicKit Plugin: Inserted track next at position \(insertIndex)")
        }
        
        invoke.resolve(["success": true, "error": ""])
    } catch {
        print("MusicKit Plugin: insertTrackNext error: \(error.localizedDescription)")
        invoke.reject("Failed to insert track next: \(error.localizedDescription)")
    }
  }
  
  @objc public func insertTrackLast(_ invoke: Invoke) {
    print("MusicKit Plugin: insertTrackLast called")
    do {
        let args = try invoke.parseArgs(InsertTrackArgs.self)
        print("MusicKit Plugin: insertTrackLast args - track: \(args.track.title)")
        
        // Get current queue and append the track
        var currentQueue = queueManager.getQueue()
        currentQueue.append(args.track)
        queueManager.updateQueue(with: currentQueue)
        
        // Update MediaPlayer queue
        let trackIds = currentQueue.map { $0.id }
        let validTrackIds = trackIds.filter { !$0.isEmpty }
        
        if !validTrackIds.isEmpty {
            let queue = MPMusicPlayerStoreQueueDescriptor(storeIDs: validTrackIds)
            player.setQueue(with: queue)
            print("MusicKit Plugin: Inserted track last")
        }
        
        invoke.resolve(["success": true, "error": ""])
    } catch {
        print("MusicKit Plugin: insertTrackLast error: \(error.localizedDescription)")
        invoke.reject("Failed to insert track last: \(error.localizedDescription)")
    }
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
        
        // Debounce track changes to prevent spam
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            let trackData = self.itemToTrack(self.player.nowPlayingItem) ?? [:]
            print("MusicKit Plugin: Track data: \(trackData)")
            print("MusicKit Plugin: Triggering musickit-track-changed")
            self.trigger("musickit-track-changed", data: [
                "track": trackData
            ])
        }
    }

    private func itemToTrack(_ item: MPMediaItem?) -> [String: JSValue]? {
        guard let item = item else {
            return nil
        }

        // Find the corresponding track in our shadow queue
        let trackId = item.playbackStoreID
        if let shadowTrack = queueManager.findTrack(byId: trackId) {
            // Use complete metadata from shadow queue
            return [
                "id": shadowTrack.id as JSValue,
                "title": shadowTrack.title as JSValue,
                "artistName": shadowTrack.artistName as JSValue,
                "albumName": shadowTrack.albumName as JSValue,
                "genreNames": shadowTrack.genreNames as JSValue,
                "durationInMillis": shadowTrack.durationInMillis as JSValue,
                "artwork": shadowTrack.artwork as JSValue
            ]
        } else {
            // Fallback to MPMediaItem data if not found in shadow queue
            return [
                "id": item.playbackStoreID as JSValue,
                "title": (item.title ?? "") as JSValue,
                "artistName": (item.artist ?? "") as JSValue,
                "albumName": (item.albumTitle ?? "") as JSValue,
                "genreNames": (item.genre ?? "") as JSValue,
                "durationInMillis": Int(item.playbackDuration * 1000) as JSValue
            ]
        }
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