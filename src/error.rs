use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Error, Serialize, Deserialize)]
pub enum Error {
    #[error("MusicKit not initialized")]
    NotInitialized,

    #[error("Authorization failed: {0}")]
    AuthorizationFailed(String),

    #[error("Playback error: {0}")]
    PlaybackError(String),

    #[error("Queue operation failed: {0}")]
    QueueError(String),

    #[error("Platform not supported")]
    PlatformNotSupported,

    #[error("Invalid parameter: {0}")]
    InvalidParameter(String),

    #[error("MusicKit error: {0}")]
    MusicKitError(String),
}

pub type Result<T> = std::result::Result<T, Error>;
