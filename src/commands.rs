use tauri::{command, AppHandle, Runtime};

use crate::{models::*, Result, MusicKitExt};

#[command]
pub fn initialize<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.music_kit().initialize()
}

#[command]
pub fn authorize<R: Runtime>(app: AppHandle<R>) -> Result<AuthorizationResponse> {
    app.music_kit().authorize()
}

#[command]
pub fn unauthorize<R: Runtime>(app: AppHandle<R>) -> Result<UnauthorizeResponse> {
    app.music_kit().unauthorize()
}

#[command]
pub fn get_authorization_status<R: Runtime>(app: AppHandle<R>) -> Result<AuthorizationStatusResponse> {
    app.music_kit().get_authorization_status()
}

#[command]
pub fn get_user_token<R: Runtime>(app: AppHandle<R>) -> Result<Option<String>> {
    app.music_kit().get_user_token()
}

#[command]
pub fn get_developer_token<R: Runtime>(app: AppHandle<R>) -> Result<Option<String>> {
    app.music_kit().get_developer_token()
}

#[command]
pub fn get_storefront_id<R: Runtime>(app: AppHandle<R>) -> Result<Option<String>> {
    app.music_kit().get_storefront_id()
}

#[command]
pub fn get_queue<R: Runtime>(app: AppHandle<R>) -> Result<QueueResponse> {
    app.music_kit().get_queue()
}

#[command]
pub fn play<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.music_kit().play()
}

#[command]
pub fn pause<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.music_kit().pause()
}

#[command]
pub fn stop<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.music_kit().stop()
}

#[command]
pub fn seek<R: Runtime>(app: AppHandle<R>, time: f64) -> Result<()> {
    app.music_kit().seek(time)
}

#[command]
pub fn next<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.music_kit().next()
}

#[command]
pub fn previous<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.music_kit().previous()
}

#[command]
pub fn skip_to_item<R: Runtime>(app: AppHandle<R>, track_id: String, start_playing: bool) -> Result<()> {
    app.music_kit().skip_to_item(track_id, start_playing)
}

#[command]
pub fn set_volume<R: Runtime>(app: AppHandle<R>, volume: f64) -> Result<()> {
    app.music_kit().set_volume(volume)
}

#[command]
pub fn set_queue<R: Runtime>(app: AppHandle<R>, tracks: Vec<MusicKitTrack>, start_playing: bool) -> Result<QueueOperationResponse> {
    app.music_kit().set_queue(tracks, start_playing)
}

#[command]
pub fn update_queue<R: Runtime>(app: AppHandle<R>, tracks: Vec<MusicKitTrack>) -> Result<QueueOperationResponse> {
    app.music_kit().update_queue(tracks)
}

#[command]
pub fn insert_track_at_position<R: Runtime>(
    app: AppHandle<R>,
    track: MusicKitTrack,
    position: usize,
) -> Result<QueueOperationResponse> {
    app.music_kit().insert_track_at_position(track, position)
}

#[command]
pub fn insert_tracks_at_position<R: Runtime>(
    app: AppHandle<R>,
    tracks: Vec<MusicKitTrack>,
    position: usize,
) -> Result<QueueOperationResponse> {
    app.music_kit().insert_tracks_at_position(tracks, position)
}

#[command]
pub fn remove_track_from_queue<R: Runtime>(app: AppHandle<R>, track_id: String) -> Result<QueueOperationResponse> {
    app.music_kit().remove_track_from_queue(track_id)
}

#[command]
pub fn insert_track_next<R: Runtime>(app: AppHandle<R>, track: MusicKitTrack) -> Result<QueueOperationResponse> {
    app.music_kit().insert_track_next(track)
}

#[command]
pub fn insert_track_last<R: Runtime>(app: AppHandle<R>, track: MusicKitTrack) -> Result<QueueOperationResponse> {
    app.music_kit().insert_track_last(track)
}

#[command]
pub fn append_tracks_to_queue<R: Runtime>(app: AppHandle<R>, tracks: Vec<MusicKitTrack>) -> Result<QueueOperationResponse> {
    app.music_kit().append_tracks_to_queue(tracks)
}

#[command]
pub fn get_current_track<R: Runtime>(app: AppHandle<R>) -> Result<Option<MusicKitTrack>> {
    app.music_kit().get_current_track()
}

#[command]
pub fn get_playback_state<R: Runtime>(app: AppHandle<R>) -> Result<StateUpdateEvent> {
    app.music_kit().get_playback_state()
}
