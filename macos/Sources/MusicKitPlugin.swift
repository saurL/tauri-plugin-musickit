import Tauri
import MusicKit
import MediaPlayer
import Combine

@available(macOS 12.0, *)
class MusicKitPlugin: Plugin {
    private var player: ApplicationMusicPlayer
    private var cancellables = Set<AnyCancellable>()
    private var currentQueue: [MusicKitTrack] = []
    private var isInitialized = false
    
    override init() {
        self.player = ApplicationMusicPlayer.shared
        super.init()
    }
    
    @objc func initialize(_ invoke: Invoke) {
        guard !isInitialized else {
            invoke.resolve(["success": true])
            return
        }
        
        setupObservers()
        isInitialized = true
        invoke.resolve(["success": true])
    }
    
    @objc func authorize(_ invoke: Invoke) {
        Task {
            do {
                let status = await MusicAuthorization.request()
                
                let authStatus = AuthorizationResponse(
                    status: status == .authorized ? "authorized" : "notAuthorized",
                    error: nil
                )
                
                let jsonData = try JSONEncoder().encode(authStatus)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                
                // Emit authorization change event
                try trigger("PLAYER_ADAPTER_EVENTS.AUTHORIZATION_STATUS_CHANGE", data: jsonString)
                
                invoke.resolve(jsonString)
            } catch {
                let authStatus = AuthorizationResponse(
                    status: "error",
                    error: error.localizedDescription
                )
                
                let jsonData = try JSONEncoder().encode(authStatus)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                invoke.resolve(jsonString)
            }
        }
    }
    
    @objc func unauthorize(_ invoke: Invoke) {
        Task {
            do {
                // Note: MusicKit doesn't have a direct unauthorize method
                // We'll just return success
                let response = UnauthorizeResponse(
                    status: "unauthorized",
                    error: nil
                )
                
                let jsonData = try JSONEncoder().encode(response)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                invoke.resolve(jsonString)
            } catch {
                let response = UnauthorizeResponse(
                    status: "error",
                    error: error.localizedDescription
                )
                
                let jsonData = try JSONEncoder().encode(response)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                invoke.resolve(jsonString)
            }
        }
    }
    
    @objc func getAuthorizationStatus(_ invoke: Invoke) {
        let status = MusicAuthorization.currentStatus
        
        let authStatus = AuthorizationStatusResponse(
            status: status == .authorized ? "authorized" : "notAuthorized"
        )
        
        do {
            let jsonData = try JSONEncoder().encode(authStatus)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            invoke.resolve(jsonString)
        } catch {
            invoke.reject("Failed to encode authorization status")
        }
    }
    
    @objc func getUserToken(_ invoke: Invoke) {
        Task {
            do {
                let token = try await MusicAuthorization.userToken
                invoke.resolve(token)
            } catch {
                invoke.resolve(nil)
            }
        }
    }
    
    @objc func getDeveloperToken(_ invoke: Invoke) {
        Task {
            do {
                let token = try await MusicAuthorization.developerToken
                invoke.resolve(token)
            } catch {
                invoke.resolve(nil)
            }
        }
    }
    
    @objc func getStorefrontId(_ invoke: Invoke) {
        Task {
            do {
                let storefront = try await MusicAuthorization.storefront
                invoke.resolve(storefront.id.rawValue)
            } catch {
                invoke.resolve(nil)
            }
        }
    }
    
    @objc func getQueue(_ invoke: Invoke) {
        let queue = QueueResponse(
            items: currentQueue,
            position: 0 // ApplicationMusicPlayer doesn't have currentEntryIndex
        )
        
        do {
            let jsonData = try JSONEncoder().encode(queue)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            invoke.resolve(jsonString)
        } catch {
            invoke.reject("Failed to encode queue")
        }
    }
    
    @objc func play(_ invoke: Invoke) {
        Task {
            do {
                try await player.play()
                invoke.resolve()
            } catch {
                invoke.reject("Play failed: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func pause(_ invoke: Invoke) {
        player.pause()
        invoke.resolve()
    }
    
    @objc func stop(_ invoke: Invoke) {
        player.stop()
        invoke.resolve()
    }
    
    @objc func seek(_ invoke: Invoke) {
        // Parse arguments from invoke data
        do {
            let args = try invoke.parseArgs(SeekArgs.self)
            player.playbackTime = args.time
            invoke.resolve()
        } catch {
            invoke.reject("Invalid seek arguments")
        }
    }
    
    @objc func next(_ invoke: Invoke) {
        Task {
            do {
                try await player.skipToNextEntry()
                invoke.resolve()
            } catch {
                invoke.reject("Skip to next failed: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func previous(_ invoke: Invoke) {
        Task {
            do {
                try await player.skipToPreviousEntry()
                invoke.resolve()
            } catch {
                invoke.reject("Skip to previous failed: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func skipToItem(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(SkipToItemArgs.self)
            
            Task {
                // Find the track in the queue and skip to it
                if currentQueue.contains(where: { $0.id == args.trackId }) {
                    // This would require custom queue management
                    // For now, we'll just resolve
                    invoke.resolve()
                } else {
                    invoke.reject("Track not found in queue")
                }
            }
        } catch {
            invoke.reject("Invalid skip to item arguments")
        }
    }
    
    @objc func setVolume(_ invoke: Invoke) {
        do {
            _ = try invoke.parseArgs(SetVolumeArgs.self)
            // ApplicationMusicPlayer doesn't have volume property
            // This would need to be implemented differently
            invoke.resolve()
        } catch {
            invoke.reject("Invalid volume arguments")
        }
    }
    
    @objc func setQueue(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(SetQueueArgs.self)
            
            Task {
                do {
                    let tracks = try parseTracksFromJson(args.tracksJson)
                    currentQueue = tracks
                    
                    // Convert tracks to MusicKit items
                    let musicItems = try await convertToMusicItems(tracks)
                    
                    // Set the queue
                    player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                    
                    // Emit queue change event
                    emitQueueUpdate()
                    
                    invoke.resolve(["success": true])
                } catch {
                    invoke.reject("Set queue failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid set queue arguments")
        }
    }
    
    @objc func updateQueue(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(UpdateQueueArgs.self)
            
            Task {
                do {
                    let tracks = try parseTracksFromJson(args.tracksJson)
                    currentQueue = tracks
                    
                    // Convert tracks to MusicKit items
                    let musicItems = try await convertToMusicItems(tracks)
                    
                    // Set the queue
                    player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                    
                    // Emit queue change event
                    emitQueueUpdate()
                    
                    invoke.resolve(["success": true])
                } catch {
                    invoke.reject("Update queue failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid update queue arguments")
        }
    }
    
    @objc func insertTrackAtPosition(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(InsertTrackArgs.self)
            
            Task {
                do {
                    let track = try parseTrackFromJson(args.trackJson)
                    
                    // Insert track at position
                    if args.position <= currentQueue.count {
                        currentQueue.insert(track, at: args.position)
                        
                        // Convert tracks to MusicKit items
                        let musicItems = try await convertToMusicItems(currentQueue)
                        
                        // Set the queue
                        player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                        
                        // Emit queue change event
                        emitQueueUpdate()
                        
                        invoke.resolve(["success": true])
                    } else {
                        invoke.reject("Position out of bounds")
                    }
                } catch {
                    invoke.reject("Insert track failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid insert track arguments")
        }
    }
    
    @objc func insertTracksAtPosition(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(InsertTracksArgs.self)
            
            Task {
                do {
                    let tracks = try parseTracksFromJson(args.tracksJson)
                    
                    // Insert tracks at position
                    if args.position <= currentQueue.count {
                        currentQueue.insert(contentsOf: tracks, at: args.position)
                        
                        // Convert tracks to MusicKit items
                        let musicItems = try await convertToMusicItems(currentQueue)
                        
                        // Set the queue
                        player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                        
                        // Emit queue change event
                        emitQueueUpdate()
                        
                        invoke.resolve(["success": true])
                    } else {
                        invoke.reject("Position out of bounds")
                    }
                } catch {
                    invoke.reject("Insert tracks failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid insert tracks arguments")
        }
    }
    
    @objc func removeTrackFromQueue(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(RemoveTrackArgs.self)
            
            Task {
                do {
                    // Remove track from queue
                    currentQueue.removeAll { $0.id == args.trackId }
                    
                    // Convert tracks to MusicKit items
                    let musicItems = try await convertToMusicItems(currentQueue)
                    
                    // Set the queue
                    player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                    
                    // Emit queue change event
                    emitQueueUpdate()
                    
                    invoke.resolve(["success": true])
                } catch {
                    invoke.reject("Remove track failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid remove track arguments")
        }
    }
    
    @objc func insertTrackNext(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(InsertTrackNextArgs.self)
            
            Task {
                do {
                    let track = try parseTrackFromJson(args.trackJson)
                    
                    // Insert track next (after current position)
                    let insertPosition = min(1, currentQueue.count)
                    currentQueue.insert(track, at: insertPosition)
                    
                    // Convert tracks to MusicKit items
                    let musicItems = try await convertToMusicItems(currentQueue)
                    
                    // Set the queue
                    player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                    
                    // Emit queue change event
                    emitQueueUpdate()
                    
                    invoke.resolve(["success": true])
                } catch {
                    invoke.reject("Insert track next failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid insert track next arguments")
        }
    }
    
    @objc func insertTrackLast(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(InsertTrackLastArgs.self)
            
            Task {
                do {
                    let track = try parseTrackFromJson(args.trackJson)
                    
                    // Insert track at the end
                    currentQueue.append(track)
                    
                    // Convert tracks to MusicKit items
                    let musicItems = try await convertToMusicItems(currentQueue)
                    
                    // Set the queue
                    player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                    
                    // Emit queue change event
                    emitQueueUpdate()
                    
                    invoke.resolve(["success": true])
                } catch {
                    invoke.reject("Insert track last failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid insert track last arguments")
        }
    }
    
    @objc func appendTracksToQueue(_ invoke: Invoke) {
        do {
            let args = try invoke.parseArgs(AppendTracksArgs.self)
            
            Task {
                do {
                    let tracks = try parseTracksFromJson(args.tracksJson)
                    
                    // Append tracks to queue
                    currentQueue.append(contentsOf: tracks)
                    
                    // Convert tracks to MusicKit items
                    let musicItems = try await convertToMusicItems(currentQueue)
                    
                    // Set the queue
                    player.queue = ApplicationMusicPlayer.Queue(for: musicItems)
                    
                    // Emit queue change event
                    emitQueueUpdate()
                    
                    invoke.resolve(["success": true])
                } catch {
                    invoke.reject("Append tracks failed: \(error.localizedDescription)")
                }
            }
        } catch {
            invoke.reject("Invalid append tracks arguments")
        }
    }
    
    @objc func getCurrentTrack(_ invoke: Invoke) {
        guard let currentEntry = player.queue.currentEntry,
              let song = currentEntry.item as? Song else {
            invoke.resolve("null")
            return
        }
        
        let track = convertSongToTrack(song)
        
        do {
            let jsonData = try JSONEncoder().encode(track)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            try trigger("PLAYER_ADAPTER_EVENTS.TRACK_CHANGE", data: jsonString)
            invoke.resolve(jsonString)
        } catch {
            invoke.reject("Failed to encode current track")
        }
    }
    
    @objc func getPlaybackState(_ invoke: Invoke) {
        let state = StateUpdateEvent(
            playing: player.playbackStatus == .playing,
            currentTrack: getCurrentTrackFromPlayer(),
            currentTime: player.playbackTime,
            duration: 0.0, // Duration not directly available
            queuePosition: 0, // Position not directly available
            shuffleMode: "off", // Shuffle mode not directly available
            repeatMode: "none", // Repeat mode not directly available
            volume: 1.0 // Volume not directly available
        )
        
        do {
            let jsonData = try JSONEncoder().encode(state)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            invoke.resolve(jsonString)
        } catch {
            invoke.reject("Failed to encode playback state")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe playback status changes
        player.playbackStatusPublisher
            .sink { [weak self] _ in
                self?.emitStateUpdate()
            }
            .store(in: &cancellables)
    }
    
    private func emitQueueUpdate() {
        let queue = QueueUpdateEvent(
            items: currentQueue,
            position: 0 // Position not directly available
        )
        
        do {
            let jsonData = try JSONEncoder().encode(queue)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            try trigger("PLAYER_ADAPTER_EVENTS.QUEUE_UPDATE", data: jsonString)
        } catch {
            print("Failed to emit queue update: \(error)")
        }
    }
    
    private func emitStateUpdate() {
        let state = StateUpdateEvent(
            playing: player.playbackStatus == .playing,
            currentTrack: getCurrentTrackFromPlayer(),
            currentTime: player.playbackTime,
            duration: 0.0, // Duration not directly available
            queuePosition: 0, // Position not directly available
            shuffleMode: "off", // Shuffle mode not directly available
            repeatMode: "none", // Repeat mode not directly available
            volume: 1.0 // Volume not directly available
        )
        
        do {
            let jsonData = try JSONEncoder().encode(state)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            try trigger("PLAYER_ADAPTER_EVENTS.STATE_UPDATE", data: jsonString)
        } catch {
            print("Failed to emit state update: \(error)")
        }
    }
    
    private func getCurrentTrackFromPlayer() -> MusicKitTrack? {
        guard let currentEntry = player.queue.currentEntry,
              let song = currentEntry.item as? Song else {
            return nil
        }
        
        return convertSongToTrack(song)
    }
    
    private func parseTracksFromJson(_ json: String) throws -> [MusicKitTrack] {
        guard let data = json.data(using: .utf8) else {
            throw MusicKitError.invalidData
        }
        
        return try JSONDecoder().decode([MusicKitTrack].self, from: data)
    }
    
    private func parseTrackFromJson(_ json: String) throws -> MusicKitTrack {
        guard let data = json.data(using: .utf8) else {
            throw MusicKitError.invalidData
        }
        
        return try JSONDecoder().decode(MusicKitTrack.self, from: data)
    }
    
    private func convertToMusicItems(_ tracks: [MusicKitTrack]) async throws -> [Song] {
        var songs: [Song] = []
        
        for track in tracks {
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id, 
                equalTo: MusicItemID(track.id)
            )
            
            do {
                let response = try await request.response()
                if let song = response.items.first {
                    songs.append(song)
                }
            } catch {
                print("Failed to load song with ID \(track.id): \(error)")
            }
        }
        
        return songs
    }
    
    private func convertToMusicItem(_ track: MusicKitTrack) async throws -> Song {
        let request = MusicCatalogResourceRequest<Song>(
            matching: \.id, 
            equalTo: MusicItemID(track.id)
        )
        
        let response = try await request.response()
        guard let song = response.items.first else {
            throw MusicKitError.networkError("Song not found")
        }
        
        return song
    }
    
    private func convertSongToTrack(_ song: Song) -> MusicKitTrack {
        return MusicKitTrack(
            id: song.id.rawValue,
            title: song.title,
            artist: song.artistName,
            album: song.albumTitle ?? "",
            duration: song.duration ?? 0.0,
            artworkUrl: song.artwork?.url(width: 600, height: 600)?.absoluteString,
            isExplicit: song.contentRating == .explicit,
            isPlayable: song.playParameters != nil
        )
    }
}

// MARK: - Argument Types

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

struct SetQueueArgs: Decodable {
    let tracksJson: String
    let startPlaying: Bool
}

struct UpdateQueueArgs: Decodable {
    let tracksJson: String
}

struct InsertTrackArgs: Decodable {
    let trackJson: String
    let position: Int
}

struct InsertTracksArgs: Decodable {
    let tracksJson: String
    let position: Int
}

struct RemoveTrackArgs: Decodable {
    let trackId: String
}

struct InsertTrackNextArgs: Decodable {
    let trackJson: String
}

struct InsertTrackLastArgs: Decodable {
    let trackJson: String
}

struct AppendTracksArgs: Decodable {
    let tracksJson: String
}

// MARK: - Error Types

enum MusicKitError: Error, LocalizedError {
    case invalidData
    case encodingFailed
    case networkError(String)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided"
        case .encodingFailed:
            return "Failed to encode data"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "Not authorized to access MusicKit"
        }
    }
}