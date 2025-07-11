import Foundation

// MARK: - Data Models

struct MusicKitTrack: Codable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: Double
    let artworkUrl: String?
    let isExplicit: Bool
    let isPlayable: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, duration
        case artworkUrl = "artwork_url"
        case isExplicit = "is_explicit"
        case isPlayable = "is_playable"
    }
}

struct AuthorizationResponse: Codable {
    let status: String // "authorized", "notAuthorized", "error"
    let error: String?
}

struct UnauthorizeResponse: Codable {
    let status: String // "unauthorized", "error"
    let error: String?
}

struct AuthorizationStatusResponse: Codable {
    let status: String // "authorized", "notAuthorized", "notInitialized"
}

struct QueueResponse: Codable {
    let items: [MusicKitTrack]
    let position: Int
}

struct QueueOperationResponse: Codable {
    let success: Bool
    let error: String?
}

struct StateUpdateEvent: Codable {
    let playing: Bool
    let currentTrack: MusicKitTrack?
    let currentTime: Double
    let duration: Double
    let queuePosition: Int
    let shuffleMode: String
    let repeatMode: String
    let volume: Double
    
    enum CodingKeys: String, CodingKey {
        case playing
        case currentTrack = "current_track"
        case currentTime = "current_time"
        case duration
        case queuePosition = "queue_position"
        case shuffleMode = "shuffle_mode"
        case repeatMode = "repeat_mode"
        case volume
    }
}

struct QueueUpdateEvent: Codable {
    let items: [MusicKitTrack]
    let position: Int
}

struct TrackChangeEvent: Codable {
    let track: MusicKitTrack
}

struct ErrorEvent: Codable {
    let error: String
    let code: String?
} 
} 