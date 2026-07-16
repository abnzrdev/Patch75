package dev.abnzr.offline_leetcode_trainer

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.RemoteException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "dev.abnzr.offline_leetcode_trainer/python_judge"
    private val timeoutHandler = Handler(Looper.getMainLooper())
    private var service: Messenger? = null
    private var bound = false
    private var pendingPayload: String? = null
    private var pendingResult: MethodChannel.Result? = null
    private var workerPid: Int? = null

    private val replies = Messenger(
        Handler(Looper.getMainLooper()) { message ->
            if (message.what == PythonJudgeService.MSG_STARTED) {
                workerPid = message.data.getInt("pid")
            } else if (message.what == PythonJudgeService.MSG_RESULT) {
                finishRun(message.data.getString("result"))
            }
            true
        },
    )

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, binder: IBinder) {
            service = Messenger(binder)
            bound = true
            pendingPayload?.let(::sendRun)
        }

        override fun onServiceDisconnected(name: ComponentName) {
            service = null
            bound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(true)
                    "run" -> startRun(call.arguments as? String, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startRun(payload: String?, result: MethodChannel.Result) {
        if (payload == null || payload.toByteArray().size > 262_144) {
            result.error("INVALID_REQUEST", "Judge payload is invalid", null)
            return
        }
        if (pendingResult != null) {
            result.error("BUSY", "Python judge is already running", null)
            return
        }
        pendingPayload = payload
        pendingResult = result
        timeoutHandler.postDelayed(::timeoutRun, 7_000)
        if (bound) {
            sendRun(payload)
        } else {
            bindService(
                Intent(this, PythonJudgeService::class.java),
                connection,
                Context.BIND_AUTO_CREATE,
            )
        }
    }

    private fun sendRun(payload: String) {
        try {
            val message = Message.obtain(null, PythonJudgeService.MSG_RUN)
            message.replyTo = replies
            message.data = Bundle().apply { putString("payload", payload) }
            service?.send(message)
        } catch (error: RemoteException) {
            finishRun(null, "Python service disconnected")
        }
    }

    private fun timeoutRun() {
        if (pendingResult == null) return
        workerPid?.let(android.os.Process::killProcess)
        finishRun(null, "Time Limit Exceeded")
        resetService()
    }

    private fun finishRun(value: String?, error: String? = null) {
        timeoutHandler.removeCallbacksAndMessages(null)
        val result = pendingResult ?: return
        pendingResult = null
        pendingPayload = null
        workerPid = null
        if (value != null) {
            result.success(value)
        } else {
            result.error("PYTHON_JUDGE", error ?: "Python judge failed", null)
        }
    }

    private fun resetService() {
        if (bound) unbindService(connection)
        bound = false
        service = null
        stopService(Intent(this, PythonJudgeService::class.java))
    }

    override fun onDestroy() {
        resetService()
        super.onDestroy()
    }
}
