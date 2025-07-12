use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum Error {
    #[error("Not initialized")]
    NotInitialized,
    #[error("Already initialized")]
    AlreadyInitialized,
    #[error("Invalid track identifier: {0}")]
    InvalidTrackIdentifier(String),
    #[error("Invalid track format: {0}")]
    InvalidTrackFormat(String),
    #[error("Platform not supported")]
    PlatformNotSupported,
    #[error("MusicKit error: {0}")]
    MusicKitError(String),
    #[error("Tauri error: {0}")]
    Tauri(String),
}

impl Serialize for Error {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

impl From<tauri::Error> for Error {
    fn from(error: tauri::Error) -> Self {
        Error::Tauri(error.to_string())
    }
}

#[cfg(mobile)]
impl From<tauri::plugin::mobile::PluginInvokeError> for Error {
    fn from(error: tauri::plugin::mobile::PluginInvokeError) -> Self {
        Error::Tauri(error.to_string())
    }
}

pub type Result<T> = std::result::Result<T, Error>;
