package com.example.prism.services

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.content.Intent
import android.app.Notification

/**
 * PRISM Notification Listener Service
 * 
 * Analyzes notification patterns from messaging apps for mood detection.
 * Does NOT store raw notification content - only metadata for sentiment patterns.
 * 
 * Tracked metadata:
 * - Package name (which app)
 * - Timestamp (when received)
 * - Priority level
 * - App category (messaging, social, etc.)
 * 
 * Filtered apps: WhatsApp, SMS/Messages, Telegram, Signal, Messenger, Discord
 */
class PrismNotificationListener : NotificationListenerService() {
    
    companion object {
        private const val TAG = "PrismNotification"
        
        // Message app package names to track
        private val FILTERED_PACKAGES = setOf(
            // WhatsApp
            "com.whatsapp",
            "com.whatsapp.w4b",
            // SMS/Messages
            "com.google.android.apps.messaging",
            "com.android.mms",
            "com.samsung.android.messaging",
            // Telegram
            "org.telegram.messenger",
            "org.telegram.messenger.web",
            // Signal
            "org.thoughtcrime.securesms",
            // Facebook Messenger
            "com.facebook.orca",
            "com.facebook.mlite",
            // Discord
            "com.discord",
            // Instagram DMs
            "com.instagram.android",
            // Slack
            "com.Slack",
            // Microsoft Teams
            "com.microsoft.teams"
        )
        
        // App category mapping
        private val APP_CATEGORIES = mapOf(
            "com.whatsapp" to "messaging",
            "com.whatsapp.w4b" to "messaging",
            "com.google.android.apps.messaging" to "sms",
            "com.android.mms" to "sms",
            "com.samsung.android.messaging" to "sms",
            "org.telegram.messenger" to "messaging",
            "org.telegram.messenger.web" to "messaging",
            "org.thoughtcrime.securesms" to "messaging",
            "com.facebook.orca" to "social",
            "com.facebook.mlite" to "social",
            "com.discord" to "social",
            "com.instagram.android" to "social",
            "com.Slack" to "work",
            "com.microsoft.teams" to "work"
        )
    }
    
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        
        val packageName = sbn.packageName ?: return
        
        // Filter to only tracked messaging apps
        if (!FILTERED_PACKAGES.contains(packageName)) {
            return
        }
        
        val notification = sbn.notification ?: return
        val timestamp = sbn.postTime
        val priority = notification.priority
        val category = APP_CATEGORIES[packageName] ?: "other"
        
        // Determine if this is a message notification (has text content indicator)
        val extras = notification.extras
        val hasText = extras?.getCharSequence(Notification.EXTRA_TEXT) != null
        val hasTitle = extras?.getCharSequence(Notification.EXTRA_TITLE) != null
        
        // Only count as message notification if it has text content
        if (!hasText && !hasTitle) {
            return
        }
        
        Log.d(TAG, "Notification from: $packageName (category: $category) at $timestamp")
        
        // Broadcast to Flutter via Intent
        broadcastNotificationEvent(packageName, timestamp, category, priority)
    }
    
    private fun broadcastNotificationEvent(
        packageName: String,
        timestamp: Long,
        category: String,
        priority: Int
    ) {
        val intent = Intent("com.prism.app.ACTION_NOTIFICATION_EVENT")
        intent.setPackage(this.packageName)
        
        intent.putExtra("eventType", "notification")
        intent.putExtra("packageName", packageName)
        intent.putExtra("timestamp", timestamp)
        intent.putExtra("category", category)
        intent.putExtra("priority", priority)
        intent.putExtra("appName", getAppDisplayName(packageName))
        
        sendBroadcast(intent)
        Log.d(TAG, "Broadcast notification event for $packageName")
    }
    
    private fun getAppDisplayName(packageName: String): String {
        return when (packageName) {
            "com.whatsapp", "com.whatsapp.w4b" -> "WhatsApp"
            "com.google.android.apps.messaging", "com.android.mms", 
            "com.samsung.android.messaging" -> "Messages"
            "org.telegram.messenger", "org.telegram.messenger.web" -> "Telegram"
            "org.thoughtcrime.securesms" -> "Signal"
            "com.facebook.orca", "com.facebook.mlite" -> "Messenger"
            "com.discord" -> "Discord"
            "com.instagram.android" -> "Instagram"
            "com.Slack" -> "Slack"
            "com.microsoft.teams" -> "Teams"
            else -> packageName.substringAfterLast(".")
        }
    }
    
    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Not tracking removals for now
    }
    
    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification listener connected")
    }
    
    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }
}
