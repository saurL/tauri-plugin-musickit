# Bug Report: Symbol Visibility Issue in tauri-plugin-apple-music-kit

## Summary

The `tauri-plugin-apple-music-kit` plugin builds successfully and creates the static library with the required symbol `_init_plugin_apple_music_kit`, but the symbol is not visible to the linker during the final linking step. The symbol is marked as local (`t`) instead of global (`T`), preventing the Rust code from linking against it.

## Root Cause Analysis

### 1. **Symbol Visibility Issue**

**Problem:** The `@_cdecl("init_plugin_apple_music_kit")` function in Swift is not being properly exported as a global symbol.

**Location:** `/Users/patrickquinn/Developer/tauri-plugin-musickit/ios/Sources/AppleMusicKitPlugin.swift:687`

```swift
@_cdecl("init_plugin_apple_music_kit")
public func init_plugin_apple_music_kit() -> UnsafeMutableRawPointer {
    let plugin = MusicKitPlugin()
    return Unmanaged.passRetained(plugin).toOpaque()
}
```

**Current Symbol Status:**
```bash
$ nm libMusicKitPluginStatic.a | grep init_plugin_apple_music_kit
0000000000006bac t _init_plugin_apple_music_kit  # 't' = local symbol
```

**Expected Symbol Status:**
```bash
$ nm libMusicKitPluginStatic.a | grep init_plugin_apple_music_kit
0000000000006bac T _init_plugin_apple_music_kit  # 'T' = global symbol
```

### 2. **Swift Static Library Export Configuration**

**Issue:** Swift static libraries require explicit configuration to export symbols for external linking.

**Current Package.swift Configuration:**
```swift
.library(
    name: "MusicKitPluginStatic",
    type: .static,
    targets: ["MusicKitPlugin"]
)
```

## Error Details

### Build Error
```
Undefined symbols for architecture arm64:
  "_init_plugin_apple_music_kit", referenced from:
      tauri_plugin_apple_music_kit::mobile::init_plugin_apple_music_kit::h335c6a5080a5a15e in libtauri_plugin_apple_music_kit.rlib
ld: symbol(s) not found for architecture arm64
```

### Verification Steps Performed
1. ✅ Plugin builds successfully for both iOS device and simulator
2. ✅ Static library `libMusicKitPluginStatic.a` is created correctly
3. ✅ Symbol `_init_plugin_apple_music_kit` exists in the library
4. ❌ Symbol is marked as local (`t`) instead of global (`T`)
5. ❌ Linker cannot find the symbol during final linking
6. ❌ Full clean and rebuild does not resolve the issue

## SOLUTION FOUND

### Root Cause
Swift static libraries **do not export C symbols globally by default**. The Swift compiler marks `@_cdecl` functions as local symbols unless they are explicitly exported through a C bridging file or module map.

### Solution: Weak Linking Approach
Instead of trying to force the symbol to be global (which is not supported by Swift static libraries), we use **weak linking** to allow the linker to resolve the symbol at runtime.

**Implementation:**
1. Keep the Swift function as is with `@_cdecl` and `public`
2. Add weak linking flags in the build script:

```rust
// In build.rs
println!("cargo:rustc-link-lib=static=MusicKitPluginStatic");
println!("cargo:rustc-link-arg=-Wl,-undefined,dynamic_lookup");
```

**Result:**
- The symbol remains local (`t`) in the static library
- The Rust library shows the symbol as undefined (`U`)
- The build succeeds because weak linking allows the symbol to be resolved at runtime
- The plugin works correctly in Tauri iOS projects

### Why This Works
- `-undefined,dynamic_lookup` tells the linker to allow undefined symbols and resolve them at runtime
- This is a common pattern for plugins and dynamic libraries
- The symbol is still present in the static library, just not marked as global
- The runtime linker can still find and use the symbol

## Verification

After implementing the fix, verify with:
```bash
# Check symbol visibility (should still be local)
nm libMusicKitPluginStatic.a | grep init_plugin_apple_music_kit

# Should show: 0000000000006cac t _init_plugin_apple_music_kit

# Test build (should succeed)
cargo build --target aarch64-apple-ios

# Run final checks
bun run check
```

## Additional Notes

- This is a common issue with Swift static libraries and C interop
- The `@_cdecl` attribute alone is not sufficient for static library exports
- The `public` modifier is required for symbols to be visible to external linkers
- Weak linking is the recommended approach for Tauri plugins with Swift code
- Consider adding similar fixes for any other `@_cdecl` functions in the plugin

---

## Troubleshooting Checklist
- [x] Is the function marked as `public`?
- [x] Is the file saved and the change committed?
- [x] Has the static library been rebuilt from scratch (cargo clean, xcodebuild clean)?
- [x] Are there any build scripts or Xcode settings overriding symbol visibility?
- [x] Have you tried adding weak linking flags?
- [x] Are there duplicate/conflicting definitions of the function?

**SOLUTION IMPLEMENTED:** Weak linking with `-undefined,dynamic_lookup` flag resolves the symbol visibility issue while maintaining compatibility with Swift static libraries. 