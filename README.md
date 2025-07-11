# Tauri Plugin apple-music-kit

[![crates.io](https://img.shields.io/crates/v/tauri-plugin-apple-music-kit)](https://crates.io/crates/tauri-plugin-apple-music-kit)
[![npm](https://img.shields.io/npm/v/tauri-plugin-apple-music-kit-api)](https://www.npmjs.com/package/tauri-plugin-apple-music-kit-api)
[![documentation](https://img.shields.io/badge/docs-API%20docs-blue)](https://docs.rs/tauri-plugin-apple-music-kit)
[![License: Apache-2.0 OR MIT](https://img.shields.io/badge/License-Apache%202.0%20OR%20MIT-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A Tauri 2 plugin focused on providing comprehensive Apple MusicKit integration for iOS and macOS applications. It allows you to programmatically control music playback, manage queues, handle authorization, and listen to native MusicKit events. The plugin provides a unified API that works across iOS and macOS platforms with proper platform-specific implementations.

## Features

### Core MusicKit Functionality
- **Authorization Management**: Request and check Apple Music authorization status
- **Playback Control**: Play, pause, stop, seek, next, previous track controls
- **Queue Management**: Set, append, insert, and remove tracks from playback queue
- **State Monitoring**: Get current track, playback state, and queue information
- **Event System**: Listen to playback state changes, track changes, and queue updates

### Platform Support
- **iOS**: Full native MusicKit integration with iOS 15+ APIs
- **macOS**: Full native MusicKit integration with macOS 12+ APIs
- **Desktop**: Stubbed implementations that return `UnsupportedPlatform` error

### MusicKit Features
- **Authorization**: Handle Apple Music subscription status and permissions
- **Playback**: Control music playback with full queue management
- **Queue Operations**: Add, remove, and reorder tracks in the playback queue
- **State Tracking**: Monitor current track, playback position, and queue state
- **Event Listening**: Real-time updates for playback state and queue changes

## Prerequisites

- Your Tauri project must be set up for iOS/macOS development
- Apple Developer Account with MusicKit capabilities enabled
- This plugin is designed for Tauri 2.x
- iOS 15+ or macOS 12+ deployment target

## Setup

There are two main parts to installing this plugin: the Rust (Core) part and the JavaScript (API Bindings) part.

### 1. Rust Crate Installation

Add the plugin to your Tauri app's `src-tauri/Cargo.toml`.

**A. Using cargo add (Recommended):**
```bash
cargo add tauri-plugin-apple-music-kit
```

**B. Manual Cargo.toml Edit:**
Add the following to your `src-tauri/Cargo.toml` under `[dependencies]`:
```toml
tauri-plugin-apple-music-kit = "0.1.0" # Replace with the desired version from crates.io
```

For local development, if you have a modified version of the plugin locally, you can use a path dependency:
```toml
tauri-plugin-apple-music-kit = { path = "/path/to/your/local/tauri-plugin-apple-music-kit" }
```

### 2. Register the Plugin (Rust)

In your `src-tauri/src/main.rs`, register the plugin with Tauri's builder:

```rust
fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_apple_music_kit::init()) // Add this line
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### 3. JavaScript/TypeScript API Installation

The JavaScript bindings provide a typed API to interact with the plugin from your frontend code. The NPM package for this plugin is `tauri-plugin-apple-music-kit-api`.

**A. Install the NPM package (Recommended):**
In your Tauri application's frontend project directory, install the package:

```bash
# Using bun
bun add tauri-plugin-apple-music-kit-api

# Using npm
npm install tauri-plugin-apple-music-kit-api

# Using pnpm
pnpm add tauri-plugin-apple-music-kit-api

# Using yarn
yarn add tauri-plugin-apple-music-kit-api
```

Ensure you install a version compatible with your Rust crate version (e.g., 0.1.0).

**B. Local Development & Linking:**
If you are actively developing this plugin and want to test changes immediately in a consuming project:

**Link the Plugin Globally:**
Navigate to the root of this plugin's directory (`tauri-plugin-apple-music-kit`) and run:
```bash
# Using bun
bun link

# Using npm
npm link

# Using yarn v1 (classic)
yarn link
```

**Link in Consuming Project:**
Then, in your Tauri application's root directory, link the globally registered package:
```bash
# Using bun
bun link tauri-plugin-apple-music-kit-api

# Using npm
npm link tauri-plugin-apple-music-kit-api

# Using yarn v1 (classic)
yarn link tauri-plugin-apple-music-kit-api
```

This setup ensures your consuming project uses your local plugin code. Remember to rebuild the plugin's JS bindings (`bun run build` in the plugin directory) after changes.

### 4. Permissions (Tauri v2+)

For Tauri v2 and later, you must explicitly grant permissions to your plugin's commands. The apple-music-kit plugin comes with a default permission set that allows all its commands.

In your app's `src-tauri/capabilities/default.json` (or your specific capability file, e.g., `mobile.json`), add the plugin's default permission set by referencing it as `"apple-music-kit:default"`:

```json
{
  "$schema": "../gen/schemas/mobile-schema.json",
  "identifier": "default",
  "description": "Default capabilities for the application.",
  "windows": [
    "main"
  ],
  "permissions": [
    "core:default",
    "apple-music-kit:default"
  ]
}
```

This grants permissions for the commands included in the plugin's default set. The default set includes:

- `allow-initialize`
- `allow-authorize`
- `allow-get-authorization-status`
- `allow-play`
- `allow-pause`
- `allow-stop`
- `allow-seek`
- `allow-next`
- `allow-previous`
- `allow-set-queue`
- `allow-get-queue`
- `allow-get-current-track`
- `allow-get-playback-state`

## Usage (JavaScript/TypeScript API)

Import the desired functions and types from the `tauri-plugin-apple-music-kit-api` package in your frontend code.

```typescript
import {
  initialize,
  authorize,
  getAuthorizationStatus,
  play,
  pause,
  stop,
  seek,
  next,
  previous,
  setQueue,
  getQueue,
  getCurrentTrack,
  getPlaybackState,
  type AuthorizationStatus,
  type MusicKitTrack,
  type MusicKitQueue,
  type PlaybackState,
  // Event listeners
  addEventListener,
  removeAllEventListeners,
  type MusicKitEventMap
} from 'tauri-plugin-apple-music-kit-api';

// Example: Initialize and authorize
async function setupMusicKit() {
  try {
    await initialize();
    const status = await authorize();
    console.log('Authorization status:', status.status);
  } catch (error) {
    console.error('Failed to setup MusicKit:', error);
  }
}

// Example: Playback control
async function handlePlayback() {
  try {
    await play();
    console.log('Playback started');
  } catch (error) {
    console.error('Failed to play:', error);
  }
}

// Example: Queue management
async function handleQueue() {
  const tracks: MusicKitTrack[] = [
    {
      id: "123456789",
      title: "Example Song",
      artist: "Example Artist",
      album: "Example Album",
      duration: 180.0,
      artworkUrl: "https://example.com/artwork.jpg",
      isExplicit: false,
      isPlayable: true
    }
  ];
  
  try {
    await setQueue(tracks);
    console.log('Queue set successfully');
  } catch (error) {
    console.error('Failed to set queue:', error);
  }
}

// Example: Get current state
async function getCurrentState() {
  try {
    const state = await getPlaybackState();
    console.log('Playing:', state.playing);
    console.log('Current track:', state.currentTrack?.title);
    console.log('Position:', state.currentTime);
  } catch (error) {
    console.error('Failed to get state:', error);
  }
}

// Example: Listen to events
async function setupEventListeners() {
  const unlistenAuth = await addEventListener('musickit://authorization-changed', (status: AuthorizationStatus) => {
    console.log('Authorization changed:', status.status);
  });

  const unlistenPlayback = await addEventListener('musickit://playback-state-changed', (state: PlaybackState) => {
    console.log('Playback state changed:', state.playing);
  });

  const unlistenQueue = await addEventListener('musickit://queue-changed', (queue: MusicKitQueue) => {
    console.log('Queue changed:', queue.items.length, 'tracks');
  });

  // Remember to clean up listeners when your component unmounts:
  // removeAllEventListeners();
}

setupEventListeners();
```

## API Details

### Commands (via JS API)

#### Authorization
```typescript
async initialize(): Promise<void>
// Initialize the MusicKit plugin

async authorize(): Promise<AuthorizationStatus>
// Request Apple Music authorization

async getAuthorizationStatus(): Promise<AuthorizationStatus>
// Get current authorization status
```

#### Playback Control
```typescript
async play(): Promise<void>
// Start playback

async pause(): Promise<void>
// Pause playback

async stop(): Promise<void>
// Stop playback

async seek(time: number): Promise<void>
// Seek to specific time (seconds)

async next(): Promise<void>
// Skip to next track

async previous(): Promise<void>
// Skip to previous track
```

#### Queue Management
```typescript
async setQueue(tracks: MusicKitTrack[]): Promise<void>
// Set the playback queue

async getQueue(): Promise<MusicKitQueue>
// Get current queue

async appendToQueue(tracks: MusicKitTrack[]): Promise<void>
// Append tracks to queue

async insertAtPosition(track: MusicKitTrack, position: number): Promise<void>
// Insert track at specific position

async removeFromQueue(trackId: string): Promise<void>
// Remove track from queue
```

#### State Information
```typescript
async getCurrentTrack(): Promise<MusicKitTrack | null>
// Get currently playing track

async getPlaybackState(): Promise<PlaybackState>
// Get current playback state

async getStorefrontId(): Promise<string>
// Get current storefront ID
```

### Events

Each event listener function returns a Promise that resolves to an unlisten function.

```typescript
async addEventListener<K extends keyof MusicKitEventMap>(
  event: K,
  callback: (payload: MusicKitEventMap[K]) => void
): Promise<UnlistenFn>
```

Available events:
- `musickit://initialized`: Plugin initialization complete
- `musickit://authorization-changed`: Authorization status changed
- `musickit://playback-state-changed`: Playback state updated
- `musickit://queue-changed`: Queue content changed
- `musickit://track-changed`: Current track changed
- `musickit://error`: Error occurred

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

interface MusicKitQueue {
  items: MusicKitTrack[];
  currentIndex: number;
}

interface AuthorizationStatus {
  status: 'authorized' | 'denied' | 'notDetermined' | 'restricted';
  subscriptionStatus?: string;
}

interface PlaybackState {
  playing: boolean;
  currentTrack?: MusicKitTrack;
  currentTime: number;
  duration: number;
  queuePosition: number;
  shuffleMode: string;
  repeatMode: string;
}
```

## Rust API (for use within src-tauri)

You can also use the plugin's functions directly from Rust code via the `MusicKitExt` trait.

```rust
use tauri_plugin_apple_music_kit::{MusicKitExt, AuthorizationStatus, PlaybackState};

// In a function where you have access to AppHandle, Window, etc.
fn example_rust_usage<R: tauri::Runtime>(app_handle: &tauri::AppHandle<R>) {
    // Check authorization status
    match app_handle.music_kit().get_authorization_status() {
        Ok(AuthorizationStatus { status, .. }) => {
            println!("Authorization status: {}", status);
        }
        Err(e) => eprintln!("Authorization error: {:?}", e),
    }

    // Get playback state
    match app_handle.music_kit().get_playback_state() {
        Ok(PlaybackState { playing, current_track, .. }) => {
            println!("Playing: {}, Track: {:?}", playing, current_track);
        }
        Err(e) => eprintln!("Playback state error: {:?}", e),
    }
}
```

## iOS/macOS Specifics

- **MusicKit Integration**: Uses native Apple MusicKit framework
- **Authorization**: Handles Apple Music subscription and permissions
- **Playback**: Controls system music player with queue management
- **Events**: Real-time updates for playback and queue changes
- **Platform Support**: iOS 15+ and macOS 12+ with proper platform guards

## Desktop Behavior

On desktop platforms (Windows, Linux), all plugin functions will result in an `Error::UnsupportedPlatform` being returned. This is by design, as the core focus is Apple MusicKit integration.

## Building the Plugin (Development)

Navigate to the root directory of this plugin: `cd tauri-plugin-apple-music-kit`

**Rust & Native Code:**
```bash
cargo build # For host
cargo build --target aarch64-apple-ios # For iOS
cargo build --target aarch64-apple-darwin # For macOS
```

**JavaScript/TypeScript Bindings:**
```bash
bun install # Or npm install, yarn install
bun run build # Or npm run build, yarn build
```

**iOS Swift Package:**
```bash
cd ios
xcodebuild -scheme MusicKitPlugin -destination 'generic/platform=iOS' build
```

## Contributing

Contributions that align with the Apple MusicKit integration focus of this plugin are welcome. Please open an issue or submit a pull request.

## License

This plugin is licensed under either of

- Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.
