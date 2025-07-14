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
        println!("cargo:warning=Executing iOS build path");
        let _target_arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap();
        let _target_vendor = std::env::var("CARGO_CFG_TARGET_VENDOR").unwrap();
        
        // Fix target architecture detection
        let target_triple = std::env::var("TARGET").unwrap();
        let sdk = if target_triple.contains("sim") { "iphonesimulator" } else { "iphoneos" };
        let destination = if sdk == "iphoneos" {
            "generic/platform=iOS"
        } else {
            "generic/platform=iOS Simulator"
        };

        println!("cargo:warning=Building for SDK: {}, destination: {}", sdk, destination);

        // Build the Swift package using xcodebuild with a specific scheme
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

        println!("cargo:warning=xcodebuild completed successfully");

        // Use the existing static library created by the Swift package
        let build_dir = format!("ios/xcode-build/Build/Products/Release-{}", sdk);
        let lib_path = format!("{}/libMusicKitPluginStatic.a", build_dir);
        
        println!("cargo:warning=Using existing static library at: {}", lib_path);

        let current_dir = std::env::current_dir().expect("Failed to get current directory");
        let absolute_lib_path = current_dir.join(&lib_path);
        let output_dir = std::env::var("OUT_DIR").unwrap();
        let lib_name = "libMusicKitPluginStatic.a";
        let output_path = format!("{}/{}", output_dir, lib_name);
        
        // Check if the library is a fat file (universal binary) or single architecture
        let file_output = Command::new("file")
            .arg(&absolute_lib_path)
            .output()
            .expect("Failed to execute file command");
        
        let file_info = String::from_utf8_lossy(&file_output.stdout);
        let is_fat_file = file_info.contains("universal binary");
        
        if is_fat_file {
            // Extract the target architecture from the target triple
            let target_arch = if target_triple.contains("aarch64") || target_triple.contains("arm64") {
                "arm64"
            } else if target_triple.contains("x86_64") {
                "x86_64"
            } else {
                panic!("Unsupported target architecture: {}", target_triple);
            };
            
            // Create a target-specific library using lipo
            let lipo_status = Command::new("lipo")
                .arg("-extract")
                .arg(target_arch)
                .arg(&absolute_lib_path)
                .arg("-output")
                .arg(&output_path)
                .status()
                .expect("Failed to execute lipo");

            if !lipo_status.success() {
                panic!("lipo failed with status: {}", lipo_status);
            }
            
            println!("cargo:warning=Extracted {} architecture from fat file", target_arch);
        } else {
            // Single architecture file, just copy it
            if let Err(e) = std::fs::copy(&absolute_lib_path, &output_path) {
                panic!("Failed to copy library: {}", e);
            }
            
            println!("cargo:warning=Copied single-architecture library");
        }
        
        println!("cargo:warning=Created target-specific library at: {}", output_path);
        println!("cargo:rustc-link-search=native={}", output_dir);
        // Try linking without specifying the library name - let the linker find it
        println!("cargo:rustc-link-lib=MusicKitPluginStatic");
    }
    
    let mut builder = tauri_plugin::Builder::new(COMMANDS);

    if target_os != "ios" {
        if target_os == "macos" {
            builder = builder.ios_path("macos");
        }
    }

    builder.build();
}
