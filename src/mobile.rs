//! The mobile-specific implementation for the plugin.

use super::Result;
use crate::models::*;
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

    pub fn initialize(&self) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("initialize", ())
            .map_err(Into::into)
    }

    pub fn authorize(&self) -> crate::Result<AuthorizationStatus> {
        self.0
            .run_mobile_plugin("authorize", ())
            .map_err(Into::into)
    }

    pub fn get_authorization_status(&self) -> crate::Result<AuthorizationStatus> {
        self.0
            .run_mobile_plugin("getAuthorizationStatus", ())
            .map_err(Into::into)
    }

    pub fn get_storefront_id(&self) -> crate::Result<String> {
        self.0
            .run_mobile_plugin("getStorefrontId", ())
            .map_err(Into::into)
    }

    pub fn get_queue(&self) -> crate::Result<MusicKitQueue> {
        self.0.run_mobile_plugin("getQueue", ()).map_err(Into::into)
    }

    pub fn play(&self) -> crate::Result<()> {
        self.0.run_mobile_plugin("play", ()).map_err(Into::into)
    }

    pub fn pause(&self) -> crate::Result<()> {
        self.0.run_mobile_plugin("pause", ()).map_err(Into::into)
    }

    pub fn stop(&self) -> crate::Result<()> {
        self.0.run_mobile_plugin("stop", ()).map_err(Into::into)
    }

    pub fn seek(&self, time: f64) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("seek", SeekPayload { time })
            .map_err(Into::into)
    }

    pub fn next(&self) -> crate::Result<()> {
        self.0.run_mobile_plugin("next", ()).map_err(Into::into)
    }

    pub fn previous(&self) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("previous", ())
            .map_err(Into::into)
    }

    pub fn skip_to_item(&self, track_id: String) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("skipToItem", SkipToItemPayload { track_id })
            .map_err(Into::into)
    }

    pub fn set_queue(&self, tracks: Vec<MusicKitTrack>) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("setQueue", SetQueuePayload { tracks })
            .map_err(Into::into)
    }

    pub fn append_to_queue(&self, tracks: Vec<MusicKitTrack>) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("appendToQueue", AppendToQueuePayload { tracks })
            .map_err(Into::into)
    }

    pub fn insert_at_position(&self, track: MusicKitTrack, position: usize) -> crate::Result<()> {
        self.0
            .run_mobile_plugin(
                "insertAtPosition",
                InsertAtPositionPayload { track, position },
            )
            .map_err(Into::into)
    }

    pub fn remove_from_queue(&self, track_id: String) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("removeFromQueue", RemoveFromQueuePayload { track_id })
            .map_err(Into::into)
    }

    pub fn get_current_track(&self) -> crate::Result<Option<MusicKitTrack>> {
        self.0
            .run_mobile_plugin("getCurrentTrack", ())
            .map_err(Into::into)
    }

    pub fn get_playback_state(&self) -> crate::Result<PlaybackState> {
        self.0
            .run_mobile_plugin("getPlaybackState", ())
            .map_err(Into::into)
    }
} 