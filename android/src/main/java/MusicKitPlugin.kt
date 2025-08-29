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

class MusicKitPlugin(private val activity: Activity) : Plugin(activity) {
    private var developerToken: String? = null
    private var userToken: String? = null
    private var pendingInvoke: Invoke? = null
    private lateinit var authenticationManager: AuthenticationManager

    override fun load(webView: WebView) {
        authenticationManager = AuthenticationFactory.createAuthenticationManager(activity)

       }

    override fun onNewIntent(intent: Intent) {
       
    }

    fun authorize(invoke: Invoke) {
        Log.d("MusicKitPlugin", "authorize called")
        Log.d("MusicKitPlugin", "developerToken is null: ${developerToken == null}")
        Log.d("MusicKitPlugin", "developerToken length: ${developerToken?.length ?: 0}")

        if (developerToken == null) {
            invoke.reject("Developer token not set.")
            return
        }

        pendingInvoke = invoke
        val intent = authenticationManager
            .createIntentBuilder(developerToken!!)
            .build()

             authLauncher = (activity as ComponentActivity).registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            val data = result.data
            val invoke = pendingInvoke
            pendingInvoke = null

            if (invoke == null) return@registerForActivityResult

            val tokenResult = authenticationManager.handleTokenResult(data)
            if (tokenResult.isError) {
                invoke.reject("Failed: ${tokenResult.error}")
            } else {
                userToken = tokenResult.musicUserToken
                val response = JSObject().apply {
                    put("status", "AUTHORIZED")
                    put("token", userToken!!)
                }
                invoke.resolve(response)
            }
        }


        authLauncher.launch(intent)
    }
}