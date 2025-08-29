// Copyright 2019-2023 Tauri Programme within The Commons Conservancy
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: MIT

package app.tauri.musickit

import android.app.Activity
import android.content.Intent
import android.util.Log
import android.webkit.WebView
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import app.tauri.plugin.Invoke
import app.tauri.plugin.JSObject
import app.tauri.plugin.Plugin
import com.apple.android.sdk.authentication.AuthenticationFactory
import com.apple.android.sdk.authentication.AuthenticationManager
import androidx.activity.ComponentActivity
import app.tauri.annotation.Command
import androidx.activity.result.ActivityResultCallback
import java.util.UUID

fun <I, O> ComponentActivity.registerActivityResultLauncher(
    contract: ActivityResultContract<I, O>,
    callback: ActivityResultCallback<O>
): ActivityResultLauncher<I> {
    val key = UUID.randomUUID().toString()
    return this.activityResultRegistry.register(key, contract, callback)
}

class AuthActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // TODO: implémentation Apple Music
    }
}


class MusicKitPlugin(private val activity: ComponentActivity) : Plugin(activity) {
    private var pendingInvoke: Invoke? = null
    private var launcher: ActivityResultLauncher<Intent>? = null

    override fun load(webView: WebView) {
        launcher = activity.registerActivityResultLauncher(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->
            if (pendingInvoke == null) return@registerActivityResultLauncher

            if (result.resultCode == Activity.RESULT_OK) {
                val token = result.data?.getStringExtra("token")
                pendingInvoke?.resolve(JSObject().apply { put("token", token ?: "") })
            } else {
                pendingInvoke?.reject("User cancelled")
            }
            pendingInvoke = null
        }
    }

    @Command
    fun authenticate(invoke: Invoke) {
        pendingInvoke = invoke
        val intent = Intent(activity, AuthActivity::class.java)
        launcher?.launch(intent)
    }
}
