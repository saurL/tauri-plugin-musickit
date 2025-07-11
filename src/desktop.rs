//! The desktop-specific implementation for the plugin.

use crate::{models::*, Result};
use serde::de::DeserializeOwned;
use tauri::{plugin::PluginApi, AppHandle, Runtime};


pub fn init<R: Runtime, C: DeserializeOwned>(
    app: &AppHandle<R>,
    _api: PluginApi<R, C>,
) -> crate::Result<MusicKitPlugin<R>> {
    Ok(MusicKitPlugin(app.clone()))
}

/// Access to the MusicKit APIs.
#[derive(Debug)]
pub struct MusicKitPlugin<R: Runtime>(AppHandle<R>);

impl<R: Runtime> crate::MusicKitPlugin<R> {
    pub fn initialize(&self) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn authorize(&self) -> Result<AuthorizationResponse> {
        // Desktop implementation - return not authorized
        Ok(AuthorizationResponse {
            status: "notAuthorized".to_string(),
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn unauthorize(&self) -> Result<UnauthorizeResponse> {
        // Desktop implementation
        Ok(UnauthorizeResponse {
            status: "unauthorized".to_string(),
            error: None,
        })
    }

    pub fn get_authorization_status(&self) -> Result<AuthorizationStatusResponse> {
        // Desktop implementation
        Ok(AuthorizationStatusResponse {
            status: "notAuthorized".to_string(),
        })
    }

    pub fn get_user_token(&self) -> Result<Option<String>> {
        // Desktop implementation
        Ok(None)
    }

    pub fn get_developer_token(&self) -> Result<Option<String>> {
        // Desktop implementation
        Ok(None)
    }

    pub fn get_storefront_id(&self) -> Result<Option<String>> {
        // Desktop implementation
        Ok(None)
    }

    pub fn get_queue(&self) -> Result<QueueResponse> {
        // Desktop implementation
        Ok(QueueResponse {
            items: vec![],
            position: 0,
        })
    }

    pub fn play(&self) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn pause(&self) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn stop(&self) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn seek(&self, _time: f64) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn next(&self) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn previous(&self) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn skip_to_item(&self, _track_id: String, _start_playing: bool) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn set_volume(&self, _volume: f64) -> Result<()> {
        // Desktop implementation
        Ok(())
    }

    pub fn set_queue(&self, _tracks: Vec<MusicKitTrack>, _start_playing: bool) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn update_queue(&self, _tracks: Vec<MusicKitTrack>) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn insert_track_at_position(&self, _track: MusicKitTrack, _position: usize) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn insert_tracks_at_position(&self, _tracks: Vec<MusicKitTrack>, _position: usize) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn remove_track_from_queue(&self, _track_id: String) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn insert_track_next(&self, _track: MusicKitTrack) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn insert_track_last(&self, _track: MusicKitTrack) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn append_tracks_to_queue(&self, _tracks: Vec<MusicKitTrack>) -> Result<QueueOperationResponse> {
        // Desktop implementation
        Ok(QueueOperationResponse {
            success: false,
            error: Some("Not supported on desktop".to_string()),
        })
    }

    pub fn get_current_track(&self) -> Result<Option<MusicKitTrack>> {
        // Desktop implementation
        Ok(None)
    }

    pub fn get_playback_state(&self) -> Result<StateUpdateEvent> {
        // Desktop implementation
        Ok(StateUpdateEvent {
            playing: false,
            current_track: None,
            current_time: 0.0,
            duration: 0.0,
            queue_position: 0,
            shuffle_mode: "off".to_string(),
            repeat_mode: "none".to_string(),
            volume: 1.0,
        })
    }
}
