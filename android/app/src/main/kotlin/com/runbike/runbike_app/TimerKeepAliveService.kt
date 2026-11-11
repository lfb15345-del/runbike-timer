package com.runbike.runbike_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * 計測・練習中に、別のアプリを開いてもタイマーと音が止まらないようにする部品。
 * 「タイマーが動いています」という通知を出している間、Androidはこのアプリを止めない。
 */
class TimerKeepAliveService : Service() {
    companion object {
        const val ACTION_STOP = "com.runbike.runbike_app.STOP_KEEP_ALIVE"
        private const val CHANNEL_ID = "runbike_timer_running"
        private const val NOTIFICATION_ID = 1001
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopKeepAlive()
            return START_NOT_STICKY
        }
        try {
            showAsForeground()
        } catch (e: Exception) {
            stopSelf()
        }
        return START_NOT_STICKY
    }

    // アプリを一覧からスワイプで消されたら、通知も片付ける
    override fun onTaskRemoved(rootIntent: Intent?) {
        stopKeepAlive()
        super.onTaskRemoved(rootIntent)
    }

    @Suppress("DEPRECATION")
    private fun stopKeepAlive() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(Service.STOP_FOREGROUND_REMOVE)
            } else {
                stopForeground(true)
            }
        } catch (e: Exception) {
            // 通知を出す前に止められた場合などは何もしない
        }
        stopSelf()
    }

    @Suppress("DEPRECATION")
    private fun showAsForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "タイマー実行中",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        // 通知をタップしたらアプリに戻る
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        var pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            pendingFlags = pendingFlags or PendingIntent.FLAG_IMMUTABLE
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, launchIntent, pendingFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        val notification = builder
            .setContentTitle("ランバイクタイマー")
            .setContentText("タイマーが動いています（タップで戻る）")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }
}
