//! The mobile-specific implementation for the plugin.

use crate::{
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
extern "C" {
    fn init_plugin_musickit() -> *mut std::ffi::c_void;
}

#[cfg(target_os = "ios")]
unsafe fn init_plugin_wrapper() -> *const std::ffi::c_void {
    init_plugin_musickit() as *const std::ffi::c_void
}

pub fn init<R: Runtime, C: DeserializeOwned>(
    _app: &AppHandle<R>,
    api: PluginApi<R, C>,
) -> crate::Result<MusicKitPlugin<R>> {
    #[cfg(target_os = "ios")]
    let handle = api.register_ios_plugin(init_plugin_wrapper)?;
    #[cfg(target_os = "android")]
    let handle = api.register_android_plugin("app.tauri.musickit", "MusicKitPlugin")?;
    Ok(MusicKitPlugin::new(handle))
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SeekPayload {
    time: f64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SetQueuePayload {
    tracks: Vec<MusicKitTrack>,
    start_playing: bool,
    start_position: usize,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SetDeveloperTokenPayload {
    token: String,
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
            .run_mobile_plugin("getAuthorizationStatus", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn get_user_token(&self) -> Result<GetUserTokenResponse> {
        self.0
            .run_mobile_plugin("getUserToken", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn get_developer_token(&self) -> Result<Option<String>> {
        self.0
            .run_mobile_plugin("getDeveloperToken", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn set_developer_token(&self, token: String) -> Result<()> {
        self.0
            .run_mobile_plugin("setDeveloperToken", SetDeveloperTokenPayload { token })
            .map_err(Into::into)
    }

    pub fn set_user_token(&self, token: String) -> Result<()> {
        self.0
            .run_mobile_plugin("setUserToken", token)
            .map_err(Into::into)
    }

    pub fn get_storefront_id(&self) -> Result<Option<String>> {
        self.0
            .run_mobile_plugin("getStorefrontId", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn get_storefront(&self) -> Result<Option<serde_json::Value>> {
        self.0
            .run_mobile_plugin("getStorefront", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn set_storefront(&self, storefront: String) -> Result<()> {
        self.0
            .run_mobile_plugin("setStorefront", storefront)
            .map_err(Into::into)
    }

    pub fn get_queue(&self) -> Result<QueueResponse> {
        self.0
            .run_mobile_plugin("getQueue", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn play(&self) -> Result<()> {
        self.0
            .run_mobile_plugin("play", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn pause(&self) -> Result<()> {
        self.0
            .run_mobile_plugin("pause", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn stop(&self) -> Result<()> {
        self.0
            .run_mobile_plugin("stop", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn seek(&self, time: f64) -> Result<()> {
        self.0
            .run_mobile_plugin("seek", SeekPayload { time })
            .map_err(Into::into)
    }

    pub fn next(&self) -> Result<()> {
        self.0
            .run_mobile_plugin("next", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn previous(&self) -> Result<()> {
        self.0
            .run_mobile_plugin("previous", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn skip_to_item(&self, track_id: String, start_playing: bool) -> Result<()> {
        self.0
            .run_mobile_plugin("skipToItem", (track_id, start_playing))
            .map_err(Into::into)
    }

    pub fn set_volume(&self, volume: f64) -> Result<()> {
        self.0
            .run_mobile_plugin("setVolume", volume)
            .map_err(Into::into)
    }

    pub fn set_queue(
        &self,
        tracks: Vec<MusicKitTrack>,
        start_playing: bool,
        start_position: usize,
    ) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin(
                "setQueue",
                SetQueuePayload {
                    tracks,
                    start_playing,
                    start_position,
                },
            )
            .map_err(Into::into)
    }

    pub fn update_queue(&self, tracks: Vec<MusicKitTrack>) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin("updateQueue", tracks)
            .map_err(Into::into)
    }

    pub fn insert_track_at_position(
        &self,
        track: MusicKitTrack,
        position: usize,
    ) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin("insertTrackAtPosition", (track, position))
            .map_err(Into::into)
    }

    pub fn insert_tracks_at_position(
        &self,
        tracks: Vec<MusicKitTrack>,
        position: usize,
    ) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin("insertTracksAtPosition", (tracks, position))
            .map_err(Into::into)
    }

    pub fn remove_track_from_queue(&self, track_id: String) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin("removeTrackFromQueue", track_id)
            .map_err(Into::into)
    }

    pub fn insert_track_next(&self, track: MusicKitTrack) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin("insertTrackNext", track)
            .map_err(Into::into)
    }

    pub fn insert_track_last(&self, track: MusicKitTrack) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin("insertTrackLast", track)
            .map_err(Into::into)
    }

    pub fn append_tracks_to_queue(
        &self,
        tracks: Vec<MusicKitTrack>,
    ) -> Result<QueueOperationResponse> {
        self.0
            .run_mobile_plugin("appendTracksToQueue", tracks)
            .map_err(Into::into)
    }

    pub fn get_current_track(&self) -> Result<Option<MusicKitTrack>> {
        self.0
            .run_mobile_plugin("getCurrentTrack", serde_json::json!({}))
            .map_err(Into::into)
    }

    pub fn get_playback_state(&self) -> Result<StateUpdateEvent> {
        self.0
            .run_mobile_plugin("getPlaybackState", serde_json::json!({}))
            .map_err(Into::into)
    }
}
