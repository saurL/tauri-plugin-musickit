use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MusicKitTrack {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration: f64,
    pub artwork_url: Option<String>,
    pub is_explicit: bool,
    pub is_playable: bool,
}

impl Default for MusicKitTrack {
    fn default() -> Self {
        Self {
            id: String::new(),
            title: String::new(),
            artist: String::new(),
            album: String::new(),
            duration: 0.0,
            artwork_url: None,
            is_explicit: false,
            is_playable: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MusicKitTrackData {
    pub id: String,
    pub title: String,
    pub artist_name: String,
    pub album_name: String,
    pub genre_names: String,
    pub artwork: String,
    pub duration_in_millis: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthorizationResponse {
    pub status: String, // "authorized", "notAuthorized", "error"
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UnauthorizeResponse {
    pub status: String, // "unauthorized", "error"
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthorizationStatusResponse {
    pub status: String, // "authorized", "notAuthorized", "notInitialized"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct QueueResponse {
    pub items: Vec<MusicKitTrack>,
    pub position: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct QueueOperationResponse {
    pub success: bool,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StateUpdateEvent {
    pub playing: bool,
    pub paused: bool,
    pub current_track: Option<MusicKitTrackData>,
    pub current_time: f64,
    pub duration: f64,
    pub progress: f64, // Add progress calculation
    pub queue_position: usize,
    pub shuffle_mode: String,
    pub repeat_mode: String,
    pub volume: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct QueueUpdateEvent {
    pub items: Vec<MusicKitTrack>,
    pub position: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TrackChangeEvent {
    pub track: MusicKitTrack,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ErrorEvent {
    pub error: String,
    pub code: Option<String>,
} 