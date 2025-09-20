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
import androidx.activity.result.ActivityResult
import java.util.UUID
import app.tauri.annotation.InvokeArg


@InvokeArg
internal class TokenArgs {
  lateinit var token: String

}

class MusicKitPlugin(private val activity: Activity) : Plugin(activity) {
    private var developerToken: String? = null
    private var userToken: String? = null
    private var pendingInvoke: Invoke? = null
    private var authenticationManager = AuthenticationFactory.createAuthenticationManager(activity)

    val key = UUID.randomUUID().toString()
    val contract = ActivityResultContracts.StartActivityForResult()
    val launcher = (activity as ComponentActivity).activityResultRegistry.register(key, contract, { result: ActivityResult ->
        if (pendingInvoke == null) return@register

        if (result.resultCode == Activity.RESULT_OK) {
            val token = result.data?.getStringExtra("token")
            Log.i("MusicKitPlugin", "user token: $token")

            userToken= token
            pendingInvoke?.resolve(JSObject().apply { put("status", "authorized") })
        } else {
            pendingInvoke?.resolve(JSObject().apply { put("status", "notAuthorized") })
        }
        pendingInvoke = null
    })
    @Command
    fun authorize(invoke: Invoke) {
        Log.i("MusicKitPlugin", "authorize called")
        Log.i("MusicKitPlugin", "developerToken is null: ${developerToken == null}")
        Log.i("MusicKitPlugin", "developerToken length: ${developerToken?.length ?: 0}")
        Log.i("MusicKitPlugin", "authenticationManager is null: ${authenticationManager == null}")
        Log.i("MusicKitPlugin", "launcher is null: ${launcher == null}")
        Log.i("MusicKitPlugin", "activity is null: ${activity == null}")
 
        if ( developerToken  == null) {
            invoke.reject("Developer token not set.")
            return
        }

        pendingInvoke = invoke
        val intent = authenticationManager
            .createIntentBuilder(developerToken!!)
            .build()

        launcher.launch(intent)
    }

    @Command
    fun setDeveloperToken(invoke: Invoke) {
        Log.i("MusicKitPlugin", "setDeveloperToken called")
        val args = invoke.parseArgs(TokenArgs::class.java)
        developerToken = args.token
        invoke.resolve()
    }

    @Command
    fun getUserToken(invoke: Invoke) {
        Log.i("MusicKitPlugin", "getUserToken called")
        if (userToken == null) {
            invoke.reject("User not authorized.")
            return
        }
        invoke.resolve(JSObject().apply { put("token", userToken ?: "") })
    }
}