use tauri::{
    plugin::{Builder, TauriPlugin},
    Manager, Runtime,
};

mod commands;
mod error;
mod events;
mod models;

#[cfg(desktop)]
mod desktop;
#[cfg(mobile)]
mod mobile;

pub use error::{Error, Result};
pub use events::*;
pub use models::*;

#[cfg(desktop)]
use desktop::MusicKitPlugin;
#[cfg(mobile)]
use mobile::MusicKitPlugin;

/// An extension trait for Tauri's `Manager` that provides access to the MusicKit plugin API.
pub trait MusicKitExt<R: Runtime> {
    fn music_kit(&self) -> &MusicKitPlugin<R>;
}

impl<R: Runtime, T: Manager<R>> MusicKitExt<R> for T {
    fn music_kit(&self) -> &MusicKitPlugin<R> {
        self.state::<MusicKitPlugin<R>>().inner()
    }
}

/// Initializes the plugin.
pub fn init<R: Runtime>() -> TauriPlugin<R> {
    Builder::new("apple-music-kit")
        .invoke_handler(tauri::generate_handler![
            commands::initialize,
            commands::authorize,
            commands::unauthorize,
            commands::get_authorization_status,
            commands::get_user_token,
            commands::get_developer_token,
            commands::get_storefront_id,
            commands::get_queue,
            commands::play,
            commands::pause,
            commands::stop,
            commands::seek,
            commands::next,
            commands::previous,
            commands::skip_to_item,
            commands::set_volume,
            commands::set_queue,
            commands::update_queue,
            commands::insert_track_at_position,
            commands::insert_tracks_at_position,
            commands::remove_track_from_queue,
            commands::insert_track_next,
            commands::insert_track_last,
            commands::append_tracks_to_queue,
            commands::get_current_track,
            commands::get_playback_state,
        ])
        .setup(|app, api| {
            #[cfg(mobile)]
            let musickit = mobile::init(app, api)?;
            #[cfg(desktop)]
            let musickit = desktop::init(app, api)?;
            app.manage(musickit);
            Ok(())
        })
        .build()
}
