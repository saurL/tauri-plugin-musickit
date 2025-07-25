// Copyright 2019-2023 Tauri Programme within The Commons Conservancy
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: MIT

const COMMANDS: &[&str] = &[
    "initialize",
    "authorize",
    "unauthorize",
    "getAuthorizationStatus",
    "getUserToken",
    "setUserToken",
    "getDeveloperToken",
    "setDeveloperToken",
    "getStorefrontId",
    "getStorefront",
    "getQueue",
    "play",
    "pause",
    "stop",
    "seek",
    "next",
    "previous",
    "skipToItem",
    "setVolume",
    "setQueue",
    "updateQueue",
    "insertTrackAtPosition",
    "insertTracksAtPosition",
    "removeTrackFromQueue",
    "insertTrackNext",
    "insertTrackLast",
    "appendTracksToQueue",
    "getCurrentTrack",
    "getPlaybackState",
];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .global_api_script_path("./api-iife.js")
        .android_path("android")
        .ios_path("ios")
        .build();
}
