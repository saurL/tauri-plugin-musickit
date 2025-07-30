# Tauri Plugin MusicKit

[![crates.io](https://img.shields.io/crates/v/tauri-plugin-musickit)](https://crates.io/crates/tauri-plugin-musickit)
[![npm](https://img.shields.io/npm/v/tauri-plugin-musickit)](https://www.npmjs.com/package/tauri-plugin-musickit)
[![documentation](https://img.shields.io/badge/docs-API%20docs-blue)](https://docs.rs/tauri-plugin-musickit)
[![License: Apache-2.0 OR MIT](https://img.shields.io/badge/License-Apache%202.0%20OR%20MIT-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A Tauri 2 plugin providing comprehensive Apple MusicKit integration for iOS and macOS applications. It allows you to programmatically control music playback, manage queues, handle authorization, and respond to music events through a unified API.

## Features

### Core MusicKit Integration
- **Authorization Management**: Request and check Apple Music authorization status
- **Playback Control**: Play, pause, stop, seek, and control music playback with immediate resolve pattern
- **Queue Management**: Set, update, insert, remove, and manage playback queue
- **Track Information**: Get current track details, album art, and metadata
- **Rich Event System**: Listen to complete playback state changes, track changes, and time updates
- **Convenience Methods**: Quick state checks (`isPlaying()`, `getCurrentTime()`, etc.)
- **Type Safety**: Full TypeScript support with accurate type definitions
- **Cross-Platform**: Works on both iOS and macOS with platform-specific optimizations

### Platform Support
- **iOS 15+**: Full MusicKit integration with native Swift APIs
- **macOS 12+**: MusicKit support with macOS-specific implementations
- **Desktop**: Stubbed implementations that return appropriate platform errors

## Prerequisites

- **Tauri 2.x** project setup
- **iOS 15+** for iOS development
- **macOS 12+** for macOS development
- **Apple Developer Account** for MusicKit authorization
- **MusicKit Capability** enabled in your app

## Installation

### 1. Rust Crate Installation

Add the plugin to your Tauri app's `src-tauri/Cargo.toml`:

```toml
[dependencies]
tauri-plugin-musickit = "0.2.6"
```

### 2. JavaScript/TypeScript API Installation

Install the TypeScript API bindings:

```bash
npm install tauri-plugin-musickit
# or
yarn add tauri-plugin-musickit
# or
pnpm add tauri-plugin-musickit
```

### 3. Register the Plugin (Rust)

In your `src-tauri/src/main.rs`, register the plugin:

```rust
fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_musickit::init())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### 4. Configure Permissions (Tauri v2)

Add the required permissions to your `src-tauri/tauri.conf.json`:

```json
{
  "tauri": {
    "allowlist": {
      "all": false
    },
    "bundle": {
      "active": true
    },
    "security": {
      "csp": null
    },
    "plugins": {
      "musickit": {
        "scope": ["authorize", "getAuthorizationStatus", "initialize", "play", "pause", "stop", "seek", "next", "previous", "skipToItem", "setVolume", "setQueue", "updateQueue", "insertTrackAtPosition", "insertTracksAtPosition", "removeTrackFromQueue", "insertTrackNext", "insertTrackLast", "appendTracksToQueue", "getCurrentTrack", "getPlaybackState", "getQueue", "getUserToken", "getDeveloperToken", "setDeveloperToken", "setUserToken", "getStorefrontId", "getStorefront"]
      }
    }
  }
}
```

## Usage

### TypeScript/JavaScript API

```typescript
import { musicKit } from 'tauri-plugin-musickit';

// Initialize the plugin
await musicKit.initialize();

// Request authorization
const authResult = await musicKit.authorize();
console.log('Authorization status:', authResult);

// Set developer token (required for authorization)
await musicKit.setDeveloperToken('your-developer-token');

// Control playback
await musicKit.play();
await musicKit.pause();
await musicKit.stop();
await musicKit.next();
await musicKit.previous();

// Seek to specific time
await musicKit.seek(30.5); // 30.5 seconds

// Set volume (iOS: system volume, macOS: may be limited)
await musicKit.setVolume(0.8);

// Get current track
const currentTrack = await musicKit.getCurrentTrack();
console.log('Current track:', currentTrack);

// Get playback state
const playbackState = await musicKit.getPlaybackState();
console.log('Playback state:', playbackState);

// Queue management
const tracks = [
  {
    id: '123456789',
    title: 'Song Title',
    artist: 'Artist Name',
    album: 'Album Name',
    duration: 180.5,
    artworkUrl: 'https://example.com/artwork.jpg',
    isExplicit: false,
    isPlayable: true
  }
];

// Set queue
await musicKit.setQueue(tracks, true, 0); // tracks, startPlaying, startPosition

// Update queue
await musicKit.updateQueue(tracks);

// Insert track at position
await musicKit.insertTrackAtPosition(tracks[0], 2);

// Insert tracks at position
await musicKit.insertTracksAtPosition(tracks, 1);

// Remove track from queue
await musicKit.removeTrackFromQueue('123456789');

// Insert track next (after current)
await musicKit.insertTrackNext(tracks[0]);

// Insert track last
await musicKit.insertTrackLast(tracks[0]);

// Append tracks to queue
await musicKit.appendTracksToQueue(tracks);

// Get queue
const queue = await musicKit.getQueue();
console.log('Current queue:', queue);

// Skip to specific track
await musicKit.skipToItem('123456789', true); // trackId, startPlaying

// Convenience methods for quick state checks
const isPlaying = await musicKit.isPlaying();
const isPaused = await musicKit.isPaused();
const currentTime = await musicKit.getCurrentTime();
const duration = await musicKit.getDuration();
const progress = await musicKit.getProgress();

// Listen to events (events now contain complete playback state)
await musicKit.addEventListener('musickit-playback-state-changed', (event) => {
  console.log('Playback state changed:', event.playing, event.currentTrack?.title);
});

await musicKit.addEventListener('musickit-track-changed', (event) => {
  console.log('Track changed:', event.currentTrack?.title, event.currentTime);
});

await musicKit.addEventListener('musickit-playback-time-changed', (event) => {
  console.log('Playback time:', event.currentTime);
});

await musicKit.addEventListener('musickit-queue-changed', (event) => {
  console.log('Queue changed:', event.success);
});

// Clean up event listeners
musicKit.removeAllEventListeners();
```

### Available Commands

| Command | Description | Parameters | Returns |
|---------|-------------|------------|---------|
| `initialize` | Initialize the MusicKit plugin | None | `void` |
| `authorize` | Request Apple Music authorization | None | `AuthorizationResponse` |
| `unauthorize` | Unauthorize Apple Music access | None | `UnauthorizeResponse` |
| `getAuthorizationStatus` | Check current authorization status | None | `AuthorizationStatusResponse` |
| `setDeveloperToken` | Set developer token for authorization | `{ token: string }` | `void` |
| `setUserToken` | Set user token | `{ token: string }` | `void` |
| `getDeveloperToken` | Get developer token | None | `string \| null` |
| `getUserToken` | Get user token | None | `string \| null` |
| `getStorefrontId` | Get storefront ID | None | `string \| null` |
| `getStorefront` | Get storefront information | None | `object \| null` |
| `play` | Start or resume playback | None | `void` |
| `pause` | Pause playback | None | `void` |
| `stop` | Stop playback | None | `void` |
| `seek` | Seek to specific time | `{ time: number }` | `void` |
| `next` | Skip to next track | None | `void` |
| `previous` | Skip to previous track | None | `void` |
| `skipToItem` | Skip to specific track | `{ trackId: string, startPlaying: boolean }` | `void` |
| `setVolume` | Set volume (iOS: system volume) | `{ volume: number }` | `void` |
| `setQueue` | Set playback queue | `{ tracks: MusicKitTrack[], startPlaying: boolean, startPosition: number }` | `QueueOperationResponse` |
| `updateQueue` | Update current queue | `{ tracks: MusicKitTrack[] }` | `QueueOperationResponse` |
| `insertTrackAtPosition` | Insert track at position | `{ track: MusicKitTrack, position: number }` | `QueueOperationResponse` |
| `insertTracksAtPosition` | Insert tracks at position | `{ tracks: MusicKitTrack[], position: number }` | `QueueOperationResponse` |
| `removeTrackFromQueue` | Remove track from queue | `{ trackId: string }` | `QueueOperationResponse` |
| `insertTrackNext` | Insert track after current | `{ track: MusicKitTrack }` | `QueueOperationResponse` |
| `insertTrackLast` | Insert track at end | `{ track: MusicKitTrack }` | `QueueOperationResponse` |
| `appendTracksToQueue` | Append tracks to queue | `{ tracks: MusicKitTrack[] }` | `QueueOperationResponse` |
| `getCurrentTrack` | Get current track information | None | `MusicKitTrack \| null` |
| `getPlaybackState` | Get current playback state | None | `PlaybackState` |
| `getQueue` | Get current queue | None | `QueueResponse` |
| `isPlaying` | Check if currently playing | None | `boolean` |
| `isPaused` | Check if currently paused | None | `boolean` |
| `getCurrentTime` | Get current playback time | None | `number` |
| `getDuration` | Get track duration | None | `number` |
| `getProgress` | Get playback progress (0-1) | None | `number` |

### Events

| Event | Description | Payload |
|-------|-------------|---------|
| `musickit-playback-state-changed` | Playback state changed | `PlaybackState` (complete state object) |
| `musickit-track-changed` | Current track changed | `PlaybackState` (complete state object) |
| `musickit-playback-time-changed` | Playback time updated | `{ currentTime: number }` |
| `musickit-queue-changed` | Queue was modified | `{ success: boolean }` |

### TypeScript Types

```typescript
interface MusicKitTrack {
  id: string;
  title: string;
  artist: string;
  album: string;
  duration: number;
  artworkUrl?: string;
  isExplicit: boolean;
  isPlayable: boolean;
}

interface AuthorizationResponse {
  status: 'authorized' | 'notAuthorized' | 'error';
  error?: string;
}

interface UnauthorizeResponse {
  status: 'unauthorized' | 'error';
  error?: string;
}

interface AuthorizationStatusResponse {
  status: 'authorized' | 'notAuthorized' | 'notInitialized';
}

interface QueueResponse {
  items: MusicKitTrack[];
  position: number;
}

interface QueueOperationResponse {
  success: boolean;
  error?: string;
}

// Complete playback state object (used by both state and track change events)
interface PlaybackState {
  playing: boolean;
  paused: boolean;
  currentTrack: {
    id: string;
    title: string;
    artistName: string;
    albumName: string;
    genreNames: string;
    durationInMillis: number;
    artwork: string;
  } | null;
  currentTime: number;
  duration: number;
  progress: number;
  queuePosition: number;
  shuffleMode: 'on' | 'off';
  repeatMode: 'none' | 'all';
  volume: number;
}

interface StateUpdateEvent extends PlaybackState {}
interface TrackChangeEvent extends PlaybackState {}

interface PlaybackTimeEvent {
  currentTime: number;
}

interface QueueChangeEvent {
  success: boolean;
}

interface MusicKitEventMap {
  'musickit-playback-state-changed': StateUpdateEvent;
  'musickit-track-changed': TrackChangeEvent;
  'musickit-playback-time-changed': PlaybackTimeEvent;
  'musickit-queue-changed': QueueChangeEvent;
}
```

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/patrickquinn/tauri-plugin-musickit.git
cd tauri-plugin-musickit

# Install dependencies
bun install

# Build the project
bun run build

# Run checks
bun run check
```

### iOS Development

```bash
# Build iOS Swift code
cd ios
xcodebuild -scheme MusicKitPlugin -destination 'generic/platform=iOS' build
```

### macOS Development

```bash
# Build macOS Swift code
cd macos
xcodebuild -scheme MusicKitPlugin -destination 'generic/platform=macOS' build
```

## Platform Notes

### iOS
- Requires iOS 15+ for MusicKit APIs
- Full MusicKit integration with native Swift implementation
- Sophisticated queue management with shadow queue system
- Supports all MusicKit features including authorization, playback control, and queue management
- Volume control is handled by the system (setVolume is a stub)

### macOS
- Requires macOS 12+ for MusicKit APIs
- Platform-specific implementation with macOS optimizations
- Uses ApplicationMusicPlayer for modern MusicKit integration
- Some features may be limited compared to iOS

### Desktop (Windows/Linux)
- Returns appropriate platform errors
- Stubbed implementations for development compatibility

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Published Packages

- **Rust Crate**: [`tauri-plugin-musickit`](https://crates.io/crates/tauri-plugin-musickit) on crates.io
- **NPM Package**: [`tauri-plugin-musickit`](https://www.npmjs.com/package/tauri-plugin-musickit) on npm
