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
    // Cooldown: Don't press back more than once every 1.5 seconds
    // This prevents the app from closing itself or affecting other apps
    private val BACK_PRESS_COOLDOWN = 1500L 
    
    private var screenHeight = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
        
        // Get screen height to detect Nav Bar later
        val metrics = resources.displayMetrics
        screenHeight = metrics.heightPixels
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // 1. Safety Checks
        if (!isBlockingEnabled || event == null) return
        
        // Strict Package Check: Ensure we don't touch other apps
        if (event.packageName?.toString() != "com.google.android.youtube") return

        // 2. Cooldown Check
        if (SystemClock.elapsedRealtime() - lastBackPressTime < BACK_PRESS_COOLDOWN) {
            return
        }

        // 3. Update Preferences (optional: move to onServiceConnected for performance if needed)
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)

        if (isBlockingEnabled) {
            val rootNode = rootInActiveWindow ?: return
            
            if (isShortsPlayer(rootNode)) {
                // Double check we are still in YouTube before firing
                if (rootNode.packageName?.toString() == "com.google.android.youtube") {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    lastBackPressTime = SystemClock.elapsedRealtime()
                }
            }
        }
    }

    private fun isShortsPlayer(root: AccessibilityNodeInfo): Boolean {
        // STRATEGY 1: Internal View IDs (The most accurate method)
        // 'reel' is the internal code name for Shorts in the YouTube APK.
        // These IDs usually do NOT appear on the Home Screen.
        
        val reelRecycler = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_recycler")
        if (reelRecycler != null && !reelRecycler.isEmpty()) return true

        val reelTouch = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_touch_helper_0")
        if (reelTouch != null && !reelTouch.isEmpty()) return true

        val reelPlayer = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_player_view")
        if (reelPlayer != null && !reelPlayer.isEmpty()) return true

        // STRATEGY 2: Backup Text Check (With Spatial Safety)
        // Only use text as a fallback, but be VERY strict about it.
        
        val shortsNodes = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsNodes != null && !shortsNodes.isEmpty()) {
            for (node in shortsNodes) {
                if (isHeaderShorts(node)) {
                    // If we found "Shorts" text that is NOT the nav bar -> Block it
                    return true
                }
            }
        }

        return false
    }

    private fun isHeaderShorts(node: AccessibilityNodeInfo): Boolean {
        val rect = Rect()
        node.getBoundsInScreen(rect)

        // 1. Check if it's the Bottom Nav Bar
        // If the text is in the bottom 15% of the screen, it's the navigation button. IGNORE IT.
        val bottomThreshold = screenHeight * 0.85 
        if (rect.top > bottomThreshold) {
            return false
        }
        
        // 2. Check if it's visible
        if (!node.isVisibleToUser) return false

        // 3. Home Screen Protection
        // The Home Screen "Shorts" shelf title is usually small. 
        // The Real Shorts Player header is usually part of a larger container.
        // (This part is tricky, so we rely mostly on Strategy 1 IDs)
        
        return true
    }

    override fun onInterrupt() {
    }
}
