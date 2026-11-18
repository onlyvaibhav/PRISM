package com.example.prism.services

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Intent
import android.util.Log

/**
 * PRISM Accessibility Service
 * 
 * Monitors typing patterns (speed, pauses, corrections) for mood analysis.
 * Does NOT store or read actual text content - only behavioral patterns.
 * 
 * Metrics tracked:
 * - Typing speed (characters per second)
 * - Pause detection (gaps between typing bursts)
 * - Backspace/correction frequency
 * - Session duration
 */
class PrismAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "PrismAccessibility"
        private const val PAUSE_THRESHOLD_MS = 2000L // 2 seconds = pause
        private const val SESSION_TIMEOUT_MS = 30000L // 30 seconds = new session
    }
    
    // Typing metrics state (no text content stored)
    private var lastEventTime: Long = 0
    private var sessionStartTime: Long = 0
    private var charCountInSession: Int = 0
    private var backspaceCount: Int = 0
    private var pauseCount: Int = 0
    private var lastTextLength: Int = 0
    private var currentPackage: String = ""
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                processTypingEvent(event)
            }
            AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED -> {
                // Selection changes can indicate corrections - track as potential backspace
                Log.d(TAG, "Text selection changed")
            }
        }
    }
    
    private fun processTypingEvent(event: AccessibilityEvent) {
        val currentTime = System.currentTimeMillis()
        val eventPackage = event.packageName?.toString() ?: ""
        
        // Get text length change (positive = added, negative = deleted/backspace)
        val currentTextLength = event.text?.firstOrNull()?.length ?: 0
        val lengthDelta = currentTextLength - lastTextLength
        lastTextLength = currentTextLength
        
        // Check for session reset (timeout or package change)
        val timeSinceLastEvent = currentTime - lastEventTime
        if (timeSinceLastEvent > SESSION_TIMEOUT_MS || eventPackage != currentPackage) {
            // End previous session and broadcast metrics if we have data
            if (charCountInSession > 0) {
                broadcastSessionMetrics(currentTime)
            }
            // Start new session
            resetSession(currentTime, eventPackage)
        } else if (timeSinceLastEvent > PAUSE_THRESHOLD_MS) {
            // Detected a pause within the same session
            pauseCount++
        }
        
        // Update metrics based on length change
        if (lengthDelta > 0) {
            // Characters added
            charCountInSession += lengthDelta
        } else if (lengthDelta < 0) {
            // Characters deleted (backspace/correction)
            backspaceCount += kotlin.math.abs(lengthDelta)
        }
        
        lastEventTime = currentTime
        
        // Broadcast real-time typing event with basic metrics
        broadcastTypingEvent(currentTime, eventPackage, lengthDelta)
    }
    
    private fun resetSession(currentTime: Long, packageName: String) {
        sessionStartTime = currentTime
        charCountInSession = 0
        backspaceCount = 0
        pauseCount = 0
        lastTextLength = 0
        currentPackage = packageName
        lastEventTime = currentTime
        Log.d(TAG, "New typing session started in: $packageName")
    }
    
    private fun broadcastTypingEvent(timestamp: Long, packageName: String, lengthDelta: Int) {
        val intent = Intent("com.prism.app.ACTION_TYPING_EVENT")
        intent.setPackage(this.packageName)
        
        // Event data
        intent.putExtra("eventType", "typing")
        intent.putExtra("timestamp", timestamp)
        intent.putExtra("packageName", packageName)
        intent.putExtra("lengthDelta", lengthDelta)
        intent.putExtra("isBackspace", lengthDelta < 0)
        
        // Running session metrics
        val sessionDuration = timestamp - sessionStartTime
        intent.putExtra("sessionDurationMs", sessionDuration)
        intent.putExtra("charCount", charCountInSession)
        intent.putExtra("backspaceCount", backspaceCount)
        intent.putExtra("pauseCount", pauseCount)
        
        // Calculate typing speed (chars per second)
        val typingSpeed = if (sessionDuration > 0) {
            (charCountInSession.toFloat() / (sessionDuration / 1000f))
        } else 0f
        intent.putExtra("typingSpeed", typingSpeed)
        
        // Calculate backspace rate (corrections per 100 chars)
        val backspaceRate = if (charCountInSession > 0) {
            (backspaceCount.toFloat() / charCountInSession.toFloat()) * 100
        } else 0f
        intent.putExtra("backspaceRate", backspaceRate)
        
        sendBroadcast(intent)
    }
    
    private fun broadcastSessionMetrics(endTime: Long) {
        val intent = Intent("com.prism.app.ACTION_TYPING_EVENT")
        intent.setPackage(this.packageName)
        
        val sessionDuration = endTime - sessionStartTime
        val typingSpeed = if (sessionDuration > 0) {
            (charCountInSession.toFloat() / (sessionDuration / 1000f))
        } else 0f
        val backspaceRate = if (charCountInSession > 0) {
            (backspaceCount.toFloat() / charCountInSession.toFloat()) * 100
        } else 0f
        
        intent.putExtra("eventType", "sessionEnd")
        intent.putExtra("timestamp", endTime)
        intent.putExtra("packageName", currentPackage)
        intent.putExtra("sessionDurationMs", sessionDuration)
        intent.putExtra("charCount", charCountInSession)
        intent.putExtra("backspaceCount", backspaceCount)
        intent.putExtra("pauseCount", pauseCount)
        intent.putExtra("typingSpeed", typingSpeed)
        intent.putExtra("backspaceRate", backspaceRate)
        
        sendBroadcast(intent)
        Log.d(TAG, "Session ended - speed: $typingSpeed c/s, backspace rate: $backspaceRate%")
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
        // Broadcast final session metrics if we have data
        if (charCountInSession > 0) {
            broadcastSessionMetrics(System.currentTimeMillis())
        }
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility service connected")
        resetSession(System.currentTimeMillis(), "")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Broadcast final session metrics
        if (charCountInSession > 0) {
            broadcastSessionMetrics(System.currentTimeMillis())
        }
        Log.d(TAG, "Accessibility service destroyed")
    }
}
