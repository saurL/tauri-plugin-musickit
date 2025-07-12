use std::process::Command;

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

    if target_os == "ios" {
        let _target_arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap();
        let target_vendor = std::env::var("CARGO_CFG_TARGET_VENDOR").unwrap();
        let sdk = if target_vendor == "apple" { "iphoneos" } else { "iphonesimulator" };
        let destination = if sdk == "iphoneos" {
            "generic/platform=iOS"
        } else {
            "generic/platform=iOS Simulator"
        };

        let status = Command::new("xcodebuild")
            .arg("build")
            .arg("-scheme")
            .arg("MusicKitPlugin")
            .arg("-destination")
            .arg(destination)
            .arg("-sdk")
            .arg(sdk)
            .arg("-configuration")
            .arg("Release")
            .arg("-derivedDataPath")
            .arg("xcode-build")
            .current_dir("ios")
            .status()
            .expect("Failed to execute xcodebuild");

        if !status.success() {
            panic!("xcodebuild failed with status: {}", status);
        }

        let build_dir = format!("ios/xcode-build/Build/Products/Release-{}", sdk);
        println!("cargo:rustc-link-search=native={}", build_dir);
    }
    
    let mut builder = tauri_plugin::Builder::new(COMMANDS);

    if target_os != "ios" {
        if target_os == "macos" {
            builder = builder.ios_path("macos");
        }
    }

    builder.build();
}
