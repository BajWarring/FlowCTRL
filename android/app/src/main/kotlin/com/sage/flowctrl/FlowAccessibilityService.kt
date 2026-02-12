package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.graphics.Rect
import android.os.SystemClock

class FlowAccessibilityService : AccessibilityService() {

    private var isBlockingEnabled = true
    private var lastBackPressTime: Long = 0
    private val BACK_PRESS_COOLDOWN = 1500L 
    private var screenHeight = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        // 1. Tell Flutter we are ALIVE immediately
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", true).apply()

        // 2. Load settings
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
        
        val metrics = resources.displayMetrics
        screenHeight = metrics.heightPixels
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        // Tell Flutter we are dead
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", false).apply()
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isBlockingEnabled || event == null) return
        if (event.packageName?.toString() != "com.google.android.youtube") return

        if (SystemClock.elapsedRealtime() - lastBackPressTime < BACK_PRESS_COOLDOWN) {
            return
        }

        // Reload pref to keep sync with UI
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)

        if (isBlockingEnabled) {
            val rootNode = rootInActiveWindow ?: return
            
            // Double check package to be safe
            if (rootNode.packageName?.toString() == "com.google.android.youtube") {
                 if (isShortsPlayer(rootNode)) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    lastBackPressTime = SystemClock.elapsedRealtime()
                }
            }
        }
    }

    private fun isShortsPlayer(root: AccessibilityNodeInfo): Boolean {
        // STRATEGY 1: Internal View IDs
        val reelRecycler = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_recycler")
        if (reelRecycler != null && !reelRecycler.isEmpty()) return true

        val reelTouch = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_touch_helper_0")
        if (reelTouch != null && !reelTouch.isEmpty()) return true

        val reelPlayer = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_player_view")
        if (reelPlayer != null && !reelPlayer.isEmpty()) return true

        // STRATEGY 2: Backup Text Check (Safe Mode)
        val shortsNodes = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsNodes != null && !shortsNodes.isEmpty()) {
            for (node in shortsNodes) {
                if (isHeaderShorts(node)) return true
            }
        }
        return false
    }

    private fun isHeaderShorts(node: AccessibilityNodeInfo): Boolean {
        val rect = Rect()
        node.getBoundsInScreen(rect)
        // Ignore Bottom Nav Bar (Bottom 15%)
        if (rect.top > (screenHeight * 0.85)) return false
        if (!node.isVisibleToUser) return false
        return true
    }

    override fun onInterrupt() {}
}
