package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context

class FlowAccessibilityService : AccessibilityService() {

    private var isBlockingEnabled = true

    override fun onServiceConnected() {
        super.onServiceConnected()
        // Load initial state
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Note: Flutter adds "flutter." prefix to shared prefs keys usually
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isBlockingEnabled || event == null) return

        // Safety check to ensure we only scan YouTube
        if (event.packageName?.toString() == "com.google.android.youtube") {
            val rootNode = rootInActiveWindow ?: return
            checkForShorts(rootNode)
        }
    }

    private fun checkForShorts(node: AccessibilityNodeInfo) {
        // Method 1: Check for "Shorts" text specifically in the UI descriptions
        // YouTube often labels the Shorts player or tab with "Shorts"
        
        if (node.text != null && node.text.toString().equals("Shorts", ignoreCase = true)) {
            // Found the Shorts tab or header -> Go Back
            performGlobalAction(GLOBAL_ACTION_BACK)
            return
        }

        if (node.contentDescription != null && node.contentDescription.toString().contains("Shorts", ignoreCase = true)) {
             // Found a description saying Shorts -> Go Back
            performGlobalAction(GLOBAL_ACTION_BACK)
            return
        }
        
        // Recursive check for children
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                checkForShorts(child)
                child.recycle()
            }
        }
    }

    override fun onInterrupt() {
        // Required method
    }
}
