package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.graphics.Rect
import android.util.DisplayMetrics

class FlowAccessibilityService : AccessibilityService() {

    private var isBlockingEnabled = true
    private var screenHeight = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
        
        // Get Screen Height to detect Navigation Bar
        val metrics = resources.displayMetrics
        screenHeight = metrics.heightPixels
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Reload pref on every event to ensure instant toggle (optional but safer)
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)

        if (!isBlockingEnabled || event == null) return

        if (event.packageName?.toString() == "com.google.android.youtube") {
            val rootNode = rootInActiveWindow ?: return
            checkForShorts(rootNode)
        }
    }

    private fun checkForShorts(node: AccessibilityNodeInfo) {
        if (node.text != null && node.text.toString().equals("Shorts", ignoreCase = true)) {
            if (shouldBlockNode(node)) {
                performGlobalAction(GLOBAL_ACTION_BACK)
                return
            }
        }

        if (node.contentDescription != null && node.contentDescription.toString().contains("Shorts", ignoreCase = true)) {
             if (shouldBlockNode(node)) {
                performGlobalAction(GLOBAL_ACTION_BACK)
                return
            }
        }
        
        // Recursive check
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                checkForShorts(child)
                child.recycle()
            }
        }
    }

    private fun shouldBlockNode(node: AccessibilityNodeInfo): Boolean {
        val rect = Rect()
        node.getBoundsInScreen(rect)

        // LOGIC: The Navigation Bar is always at the bottom.
        // If the "Shorts" text is in the bottom 15% of the screen, it is the Nav Button.
        // We DO NOT want to block the Nav Button (that crashes the app).
        // We only want to block the "Shorts" header or player content which is usually at the top or middle.
        
        val bottomThreshold = screenHeight * 0.85 // 85% down the screen
        
        if (rect.top > bottomThreshold) {
            // This is likely the bottom navigation bar -> IGNORE IT
            return false
        }
        
        // If it's not at the bottom, it's the player or the shelf -> BLOCK IT
        return true
    }

    override fun onInterrupt() {
    }
}
