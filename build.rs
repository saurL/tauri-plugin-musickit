const COMMANDS: &[&str] = &[
    "initialize",
    "authorize",
    "get_authorization_status",
    "get_storefront_id",
    "get_queue",
    "play",
    "pause",
    "stop",
    "seek",
    "next",
    "previous",
    "skip_to_item",
    "set_queue",
    "append_to_queue",
    "insert_at_position",
    "remove_from_queue",
    "get_current_track",
    "get_playback_state",
];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .ios_path("ios")
        .build();
}
