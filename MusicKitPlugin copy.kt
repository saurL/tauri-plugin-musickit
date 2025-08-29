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
import app.tauri.annotation.Command
import androidx.activity.ComponentActivity


class MusicKitPlugin(private val activity: Activity) : Plugin(activity) {
    private var developerToken: String? = null
    private var userToken: String? = null
    private var pendingInvoke: Invoke? = null
    private var authenticationManager = AuthenticationFactory.createAuthenticationManager(activity)
    private var authLauncher = (activity as ComponentActivity ).registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
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
    @Command
    fun authorize(invoke: Invoke) {
        Log.i("MusicKitPlugin", "authorize called")
        Log.i("MusicKitPlugin", "developerToken is null: ${developerToken == null}")
        Log.i("MusicKitPlugin", "developerToken length: ${developerToken?.length ?: 0}")
        Log.i("MusicKitPlugin", "authenticationManager is null: ${authenticationManager == null}")
        Log.i("MusicKitPlugin", "authLauncher is null: ${authLauncher == null}")
        Log.i("MusicKitPlugin", "activity is null: ${activity == null}")
        if (developerToken == null) {
            invoke.reject("Developer token not set.")
            return
        }

        pendingInvoke = invoke
        val intent = authenticationManager
            .createIntentBuilder(developerToken!!)
            .build()

        authLauncher.launch(intent)
    }
}