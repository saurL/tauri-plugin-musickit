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
import android.os.Bundle
import androidx.activity.result.ActivityResult
class AuthActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // TODO: implémenter Apple Music
        // Exemple pour renvoyer un token de test :
        val resultIntent = Intent().apply { putExtra("token", "TOKEN_TEST") }
        setResult(Activity.RESULT_OK, resultIntent)
        finish()
    }
}

class MusicKitPlugin(private val activity: ComponentActivity) : Plugin(activity) {
    private var pendingInvoke: Invoke? = null
    private var launcher: ActivityResultLauncher<Intent>? = null

    override fun load(webView: WebView) {
        val key = UUID.randomUUID().toString()
        val contract = ActivityResultContracts.StartActivityForResult()

        launcher = activity.activityResultRegistry.register(key, contract, { result: ActivityResult ->
            if (pendingInvoke == null) return@register

            if (result.resultCode == Activity.RESULT_OK) {
                val token = result.data?.getStringExtra("token")
                pendingInvoke?.resolve(JSObject().apply { put("token", token ?: "") })
            } else {
                pendingInvoke?.reject("User cancelled")
            }
            pendingInvoke = null
        })

    }

    @Command
    fun authenticate(invoke: Invoke) {
        pendingInvoke = invoke
        val intent = Intent(activity, AuthActivity::class.java)
        launcher?.launch(intent)
    }
}
