//! The mobile-specific implementation for the plugin.

use crate::{
    error::Error,
    models::{
        AuthorizationResponse, AuthorizationStatusResponse, MusicKitTrack, QueueOperationResponse,
        QueueResponse, StateUpdateEvent, UnauthorizeResponse,
    },
    Result,
};
use serde::{de::DeserializeOwned, Serialize};
use tauri::{
    plugin::{PluginApi, PluginHandle},
    AppHandle, Runtime,
};

#[cfg(target_os = "ios")]
tauri::ios_plugin_binding!(init_plugin_apple_music_kit);

pub fn init<R: Runtime, C: DeserializeOwned>(
    _app: &AppHandle<R>,
    api: PluginApi<R, C>,
) -> crate::Result<MusicKitPlugin<R>> {
    #[cfg(target_os = "ios")]
    let handle = api.register_ios_plugin(init_plugin_apple_music_kit)?;
    #[cfg(target_os = "android")]
    let handle = api.register_android_plugin("com.plugin.apple-music-kit", "MusicKitPlugin")?;
    Ok(MusicKitPlugin::new(handle))
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SeekPayload {
    time: f64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SkipToItemPayload {
    track_id: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SetQueuePayload {
    tracks: Vec<MusicKitTrack>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct AppendToQueuePayload {
    tracks: Vec<MusicKitTrack>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct InsertAtPositionPayload {
    track: MusicKitTrack,
    position: usize,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct RemoveFromQueuePayload {
    track_id: String,
}

#[derive(Debug)]
pub struct MusicKitPlugin<R: Runtime>(PluginHandle<R>);

impl<R: Runtime> MusicKitPlugin<R> {
    pub fn new(handle: PluginHandle<R>) -> Self {
        Self(handle)
    }

    pub fn initialize(&self) -> Result<()> {
        self.0
            .run_mobile_plugin("initialize", ())
            .map_err(Into::into)
    }

    pub fn authorize(&self) -> Result<AuthorizationResponse> {
        self.0
            .run_mobile_plugin("authorize", ())
            .map_err(Into::into)
    }

    pub fn unauthorize(&self) -> Result<UnauthorizeResponse> {
        Ok(UnauthorizeResponse {
            status: "unauthorized".to_string(),
            error: None,
        })
    }

    pub fn get_authorization_status(&self) -> Result<AuthorizationStatusResponse> {
        self.0
            .run_mobile_plugin("getAuthorizationStatus", ())
            .map_err(Into::into)
    }

    pub fn get_user_token(&self) -> Result<Option<String>> {
        Ok(None)
    }

    pub fn get_developer_token(&self) -> Result<Option<String>> {
        Ok(None)
    }

    pub fn get_storefront_id(&self) -> Result<Option<String>> {
        self.0
            .run_mobile_plugin("getStorefrontId", ())
            .map(Some)
            .map_err(Into::into)
    }

    pub fn get_queue(&self) -> Result<QueueResponse> {
        self.0.run_mobile_plugin("getQueue", ()).map_err(Into::into)
    }

    pub fn play(&self) -> Result<()> {
        self.0.run_mobile_plugin("play", ()).map_err(Into::into)
    }

    pub fn pause(&self) -> Result<()> {
        self.0.run_mobile_plugin("pause", ()).map_err(Into::into)
    }

    pub fn stop(&self) -> Result<()> {
        self.0.run_mobile_plugin("stop", ()).map_err(Into::into)
    }

    pub fn seek(&self, time: f64) -> Result<()> {
        self.0
            .run_mobile_plugin("seek", SeekPayload { time })
            .map_err(Into::into)
    }

    pub fn next(&self) -> Result<()> {
        self.0.run_mobile_plugin("next", ()).map_err(Into::into)
    }

    pub fn previous(&self) -> Result<()> {
        self.0
            .run_mobile_plugin("previous", ())
            .map_err(Into::into)
    }

    pub fn skip_to_item(&self, track_id: String, _start_playing: bool) -> Result<()> {
        self.0
            .run_mobile_plugin("skipToItem", SkipToItemPayload { track_id })
            .map_err(Into::into)
    }

    pub fn set_volume(&self, _volume: f64) -> Result<()> {
        Ok(())
    }

    pub fn set_queue(
        &self,
        tracks: Vec<MusicKitTrack>,
        _start_playing: bool,
    ) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin::<()>("setQueue", SetQueuePayload { tracks })?;
        Ok(QueueOperationResponse {
            success: true,
            error: None,
        })
    }

    pub fn update_queue(&self, _tracks: Vec<MusicKitTrack>) -> Result<QueueOperationResponse> {
        Err(Error::PlatformNotSupported)
    }

    pub fn insert_track_at_position(
        &self,
        track: MusicKitTrack,
        position: usize,
    ) -> Result<QueueOperationResponse> {
        self.0.run_mobile_plugin::<()>(
            "insertAtPosition",
            InsertAtPositionPayload { track, position },
        )?;
        Ok(QueueOperationResponse {
            success: true,
            error: None,
        })
    }

    pub fn insert_tracks_at_position(
        &self,
        _tracks: Vec<MusicKitTrack>,
        _position: usize,
    ) -> Result<QueueOperationResponse> {
        Err(Error::PlatformNotSupported)
    }

    pub fn remove_track_from_queue(&self, track_id: String) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin::<()>("removeFromQueue", RemoveFromQueuePayload { track_id })?;
        Ok(QueueOperationResponse {
            success: true,
            error: None,
        })
    }

    pub fn insert_track_next(&self, _track: MusicKitTrack) -> Result<QueueOperationResponse> {
        Err(Error::PlatformNotSupported)
    }

    pub fn insert_track_last(&self, _track: MusicKitTrack) -> Result<QueueOperationResponse> {
        Err(Error::PlatformNotSupported)
    }

    pub fn append_tracks_to_queue(
        &self,
        tracks: Vec<MusicKitTrack>,
    ) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin::<()>("appendToQueue", AppendToQueuePayload { tracks })?;
        Ok(QueueOperationResponse {
            success: true,
            error: None,
        })
    }

    pub fn get_current_track(&self) -> Result<Option<MusicKitTrack>> {
        self.0
            .run_mobile_plugin("getCurrentTrack", ())
            .map_err(Into::into)
    }

    pub fn get_playback_state(&self) -> Result<StateUpdateEvent> {
        self.0
            .run_mobile_plugin("getPlaybackState", ())
            .map_err(Into::into)
    }
} 