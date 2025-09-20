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
            val tokenResult = authenticationManager.handleTokenResult(result.data!!)
            userToken= tokenResult.getMusicUserToken()

            Log.i("MusicKitPlugin", "user token: $userToken")

            pendingInvoke?.resolve(JSObject().apply { put("status", "authorized") })
        } else {
            pendingInvoke?.resolve(JSObject().apply { put("status", "notAuthorized") })
        }
        pendingInvoke = null
    })
    @Command
    fun authorize(invoke: Invoke) {
 
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
        invoke.resolve(JSObject().apply { put("token", userToken!!) })
    }
}