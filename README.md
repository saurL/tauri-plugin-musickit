# Tauri Plugin apple-music-kit

[![crates.io](https://img.shields.io/crates/v/tauri-plugin-apple-music-kit)](https://crates.io/crates/tauri-plugin-apple-music-kit)
[![npm](https://img.shields.io/npm/v/tauri-plugin-apple-music-kit-api)](https://www.npmjs.com/package/tauri-plugin-apple-music-kit-api)
[![documentation](https://img.shields.io/badge/docs-API%20docs-blue)](https://docs.rs/tauri-plugin-apple-music-kit)
[![License: Apache-2.0 OR MIT](https://img.shields.io/badge/License-Apache%202.0%20OR%20MIT-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A Tauri 2 plugin focused on providing comprehensive Apple MusicKit integration for iOS and macOS applications. It allows you to programmatically control music playback, manage queues, handle authorization, and respond to music events through a unified API.

## Features

### Core MusicKit Integration
- **Authorization Management**: Request and check Apple Music authorization status
- **Playback Control**: Play, pause, skip, and control music playback
- **Queue Management**: Add tracks to queue, manage playback queue
- **Track Information**: Get current track details, album art, and metadata
- **Event System**: Listen to playback state changes and music events
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
tauri-plugin-apple-music-kit = "0.1.0"
```

### 2. JavaScript/TypeScript API Installation

Install the TypeScript API bindings:

```bash
npm install tauri-plugin-apple-music-kit-api
# or
yarn add tauri-plugin-apple-music-kit-api
# or
pnpm add tauri-plugin-apple-music-kit-api
```

### 3. Register the Plugin (Rust)

In your `src-tauri/src/main.rs`, register the plugin:

```rust
fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_apple_music_kit::init())
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
      "apple-music-kit": {
        "scope": ["authorize", "getAuthorizationStatus", "initialize", "play", "pause", "skipToNext", "skipToPrevious", "getCurrentTrack", "getPlaybackState", "addToQueue", "getQueue", "getUserToken", "getDeveloperToken", "getStorefrontId"]
      }
    }
  }
}
```

## Usage

### TypeScript/JavaScript API

```typescript
import { invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';

// Initialize the plugin
await invoke('plugin:apple-music-kit|initialize');

// Request authorization
const authResult = await invoke('plugin:apple-music-kit|authorize');
console.log('Authorization status:', authResult);

// Control playback
await invoke('plugin:apple-music-kit|play');
await invoke('plugin:apple-music-kit|pause');
await invoke('plugin:apple-music-kit|skipToNext');
await invoke('plugin:apple-music-kit|skipToPrevious');

// Get current track
const currentTrack = await invoke('plugin:apple-music-kit|getCurrentTrack');
console.log('Current track:', currentTrack);

// Get playback state
const playbackState = await invoke('plugin:apple-music-kit|getPlaybackState');
console.log('Playback state:', playbackState);

// Add track to queue
await invoke('plugin:apple-music-kit|addToQueue', {
  trackId: '123456789'
});

// Listen to events
await listen('apple-music-kit://playback-state-changed', (event) => {
  console.log('Playback state changed:', event.payload);
});

await listen('apple-music-kit://track-changed', (event) => {
  console.log('Track changed:', event.payload);
});
```

### Available Commands

| Command | Description | Parameters | Returns |
|---------|-------------|------------|---------|
| `initialize` | Initialize the MusicKit plugin | None | `{ success: boolean }` |
| `authorize` | Request Apple Music authorization | None | `{ status: string }` |
| `getAuthorizationStatus` | Check current authorization status | None | `{ status: string }` |
| `play` | Start or resume playback | None | `{ success: boolean }` |
| `pause` | Pause playback | None | `{ success: boolean }` |
| `skipToNext` | Skip to next track | None | `{ success: boolean }` |
| `skipToPrevious` | Skip to previous track | None | `{ success: boolean }` |
| `getCurrentTrack` | Get current track information | None | `TrackInfo \| null` |
| `getPlaybackState` | Get current playback state | None | `PlaybackState` |
| `addToQueue` | Add track to queue | `{ trackId: string }` | `{ success: boolean }` |
| `getQueue` | Get current queue | None | `TrackInfo[]` |
| `getUserToken` | Get user token (iOS only) | None | `string \| null` |
| `getDeveloperToken` | Get developer token (iOS only) | None | `string \| null` |
| `getStorefrontId` | Get storefront ID | None | `string` |

### Events

| Event | Description | Payload |
|-------|-------------|---------|
| `apple-music-kit://playback-state-changed` | Playback state changed | `PlaybackState` |
| `apple-music-kit://track-changed` | Current track changed | `TrackInfo` |
| `apple-music-kit://queue-changed` | Queue updated | `TrackInfo[]` |
| `apple-music-kit://authorization-changed` | Authorization status changed | `{ status: string }` |

### TypeScript Types

```typescript
interface TrackInfo {
  id: string;
  title: string;
  artist: string;
  album: string;
  artworkUrl?: string;
  duration: number;
  isExplicit: boolean;
}

interface PlaybackState {
  isPlaying: boolean;
  isPaused: boolean;
  isStopped: boolean;
  currentTime: number;
  duration: number;
  repeatMode: 'none' | 'one' | 'all';
  shuffleMode: 'off' | 'on';
}

interface AuthorizationStatus {
  status: 'notDetermined' | 'denied' | 'restricted' | 'authorized';
}
```

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/patrickquinn/tauri-plugin-apple-music-kit.git
cd tauri-plugin-apple-music-kit

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
- Supports all MusicKit features including authorization, playback control, and queue management

### macOS
- Requires macOS 12+ for MusicKit APIs
- Platform-specific implementation with macOS optimizations
- Some features may be limited compared to iOS

### Desktop (Windows/Linux)
- Returns `UnsupportedPlatform` errors
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

- **Rust Crate**: [`tauri-plugin-apple-music-kit`](https://crates.io/crates/tauri-plugin-apple-music-kit) on crates.io
- **NPM Package**: [`tauri-plugin-apple-music-kit-api`](https://www.npmjs.com/package/tauri-plugin-apple-music-kit-api) on npm
