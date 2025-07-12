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
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap();
    println!("cargo:warning=Building for target OS: {}", target_os);
    
    let mut builder = tauri_plugin::Builder::new(COMMANDS);

    if target_os == "ios" {
        builder = builder.ios_path("ios");
    } else if target_os == "macos" {
        builder = builder.ios_path("macos");
    }

    builder.build();
}
