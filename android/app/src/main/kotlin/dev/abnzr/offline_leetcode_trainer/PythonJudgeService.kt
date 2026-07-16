package dev.abnzr.offline_leetcode_trainer

import android.app.Service
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import kotlin.concurrent.thread

class PythonJudgeService : Service() {
    companion object {
        const val MSG_RUN = 1
        const val MSG_STARTED = 2
        const val MSG_RESULT = 3
    }

    private val messenger = Messenger(
        Handler(Looper.getMainLooper()) { message ->
            if (message.what == MSG_RUN) execute(message)
            true
        },
    )

    override fun onBind(intent: Intent): IBinder = messenger.binder

    private fun execute(message: Message) {
        val reply = message.replyTo ?: return
        reply.send(
            Message.obtain(null, MSG_STARTED).apply {
                data = Bundle().apply { putInt("pid", android.os.Process.myPid()) }
            },
        )
        val payload = message.data.getString("payload") ?: return
        thread(name = "python-judge") {
            val result = try {
                if (!Python.isStarted()) Python.start(AndroidPlatform(this))
                Python.getInstance()
                    .getModule("judge_runner")
                    .callAttr("run", payload)
                    .toString()
            } catch (error: Throwable) {
                "{\"status\":\"error\",\"stdout\":\"\",\"stderr\":" +
                    org.json.JSONObject.quote(error.toString()) +
                    ",\"executionTimeMs\":0,\"memoryUsageBytes\":null," +
                    "\"passedTests\":0,\"totalTests\":0,\"testResults\":[]}"
            }
            reply.send(
                Message.obtain(null, MSG_RESULT).apply {
                    data = Bundle().apply { putString("result", result.take(262_144)) }
                },
            )
            stopSelf()
        }
    }
}
