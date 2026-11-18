package com.example.prism

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.BroadcastReceiver
import android.content.IntentFilter

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.prism.app/settings"
    private val TYPING_CHANNEL = "com.prism.app/typing_events"
    private val NOTIFICATION_CHANNEL = "com.prism.app/notification_events"
    
    private var typingEventSink: EventChannel.EventSink? = null
    private var notificationEventSink: EventChannel.EventSink? = null
    // The previous implementation used "com.prism.app/settings". 
    // I should probably stick to one channel for "system/platform" interactions or separate if it gets big. 
    // "com.prism.app/tracking" might be better for data. 
    // But since I already have settings setup, I'll add a new channel "com.prism.app/tracking" or just use "com.prism.app/settings" for now to minimize boilerplate.
    // Actually, let's keep it clean. I'll use "com.prism.app/settings" for now as it's set up. 
    // Wait, the user plan says "Integrate via MethodChannel".
    
    // Let's add the case to the existing callback.


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Open system accessibility settings
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Could not open accessibility settings", e.message)
                    }
                }
                
                // Open notification listener settings
                "openNotificationListenerSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Could not open notification listener settings", e.message)
                    }
                }
                
                // Open app notification settings (for push notifications)
                "openAppNotificationSettings" -> {
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = android.net.Uri.parse("package:$packageName")
                            }
                        }
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Could not open app notification settings", e.message)
                    }
                }
                
                // Open app usage access settings
                "openUsageAccessSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Could not open usage access settings", e.message)
                    }
                }
                
                // Check if accessibility service is enabled - IMPROVED CHECK
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                
                // Check if notification listener is enabled
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }
                
                // Check if usage access is granted
                "isUsageAccessGranted" -> {
                    try {
                        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            appOps.unsafeCheckOpNoThrow(
                                AppOpsManager.OPSTR_GET_USAGE_STATS,
                                Process.myUid(),
                                packageName
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            appOps.checkOpNoThrow(
                                AppOpsManager.OPSTR_GET_USAGE_STATS,
                                Process.myUid(),
                                packageName
                            )
                        }
                        result.success(mode == AppOpsManager.MODE_ALLOWED)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                // Get App Usage Stats
                "getAppUsageStats" -> {
                    val start = call.argument<Long>("start")
                    val end = call.argument<Long>("end")
                    if (start != null && end != null) {
                        result.success(getUsageStats(start, end))
                    } else {
                        result.error("INVALID_ARGS", "Start and End time required", null)
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }


        // Setup Typing Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TYPING_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    typingEventSink = events
                    registerTypingReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterTypingReceiver()
                    typingEventSink = null
                }
            }
        )
        
        // Setup Notification Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    notificationEventSink = events
                    registerNotificationReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterNotificationReceiver()
                    notificationEventSink = null
                }
            }
        )
    }

    private val typingReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.prism.app.ACTION_TYPING_EVENT") {
                val data = HashMap<String, Any>()
                
                // Event metadata
                data["eventType"] = intent.getStringExtra("eventType") ?: "typing"
                data["timestamp"] = intent.getLongExtra("timestamp", 0)
                data["packageName"] = intent.getStringExtra("packageName") ?: ""
                
                // Typing event data
                data["lengthDelta"] = intent.getIntExtra("lengthDelta", 0)
                data["isBackspace"] = intent.getBooleanExtra("isBackspace", false)
                
                // Session metrics
                data["sessionDurationMs"] = intent.getLongExtra("sessionDurationMs", 0)
                data["charCount"] = intent.getIntExtra("charCount", 0)
                data["backspaceCount"] = intent.getIntExtra("backspaceCount", 0)
                data["pauseCount"] = intent.getIntExtra("pauseCount", 0)
                
                // Calculated metrics
                data["typingSpeed"] = intent.getFloatExtra("typingSpeed", 0f)
                data["backspaceRate"] = intent.getFloatExtra("backspaceRate", 0f)
                
                typingEventSink?.success(data)
            }
        }
    }

    private fun registerTypingReceiver() {
        val filter = IntentFilter("com.prism.app.ACTION_TYPING_EVENT")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(typingReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(typingReceiver, filter)
        }
    }

    private fun unregisterTypingReceiver() {
        try {
            unregisterReceiver(typingReceiver)
        } catch (e: Exception) {
            // Receiver not registered
        }
    }
    
    // Notification Receiver
    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.prism.app.ACTION_NOTIFICATION_EVENT") {
                val data = HashMap<String, Any>()
                
                data["eventType"] = intent.getStringExtra("eventType") ?: "notification"
                data["packageName"] = intent.getStringExtra("packageName") ?: ""
                data["timestamp"] = intent.getLongExtra("timestamp", 0)
                data["category"] = intent.getStringExtra("category") ?: "other"
                data["priority"] = intent.getIntExtra("priority", 0)
                data["appName"] = intent.getStringExtra("appName") ?: ""
                
                notificationEventSink?.success(data)
            }
        }
    }
    
    private fun registerNotificationReceiver() {
        val filter = IntentFilter("com.prism.app.ACTION_NOTIFICATION_EVENT")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(notificationReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(notificationReceiver, filter)
        }
    }
    
    private fun unregisterNotificationReceiver() {
        try {
            unregisterReceiver(notificationReceiver)
        } catch (e: Exception) {
            // Receiver not registered
        }
    }
    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponentName = ComponentName(this, "com.example.prism.services.PrismAccessibilityService")
        
        val enabledServicesSetting = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)
        
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && enabledService == expectedComponentName) {
                return true
            }
            // Also check by package name if component name doesn't match exactly
            if (componentNameString.contains(packageName) && 
                componentNameString.contains("PrismAccessibilityService")) {
                return true
            }
        }
        return false
    }
    
    /**
     * Check if notification listener service is enabled
     */
    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        
        return enabledListeners.contains(packageName)
    }

    private fun getUsageStats(start: Long, end: Long): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryAndAggregateUsageStats(start, end)
        
        val result = ArrayList<Map<String, Any>>()
        for ((packageName, usageStats) in stats) {
            if (usageStats.totalTimeInForeground > 0) {
                val map = HashMap<String, Any>()
                map["packageName"] = packageName
                map["totalTimeInForeground"] = usageStats.totalTimeInForeground
                map["lastTimeUsed"] = usageStats.lastTimeUsed
                result.add(map)
            }
        }
        return result
    }
}
