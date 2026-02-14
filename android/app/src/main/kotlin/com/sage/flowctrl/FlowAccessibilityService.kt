package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import android.content.SharedPreferences
import android.content.Context
import android.os.SystemClock
import android.graphics.Rect
import android.util.DisplayMetrics
import android.view.WindowManager
import kotlinx.coroutines.*

class FlowAccessibilityService : AccessibilityService() {

    // --- CONFIGURATION ---
    private val BACK_PRESS_COOLDOWN = 1500L
    private val CHECK_INTERVAL = 1000L // Check every 1 second when active

    // --- STATE ---
    private var lastBackPressTime: Long = 0
    private var screenWidth: Int = 0
    private var isProcessingBlockedContent = false
    private var currentBlockedPackage: String? = null
    
    // --- COROUTINES ---
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var checkJob: Job? = null

    // --- CACHED SETTINGS (Updated on every event to stay fresh but avoid disk reads in loop) ---
    private var isBlockingEnabled = true
    private var isYouTubeBlocked = true
    private var isInstagramBlocked = true

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        // 1. Initialize Screen Metrics (For "Right-Side" Rule)
        val metrics = DisplayMetrics()
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager.defaultDisplay.getMetrics(metrics)
        screenWidth = metrics.widthPixels

        // 2. Set "Service Active" flag
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", true).apply()

        // 3. Start in "Battery Saver" mode (Listen only to target apps)
        updateServiceConfig(listenToAll = false)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Refresh Settings Cache (Cheap operation)
        refreshSettings()

        if (!isBlockingEnabled) {
            if (isProcessingBlockedContent) onBlockedContentExited()
            return
        }

        // If we are currently tracking a blocked app, we rely on the periodic checker 
        // AND the event to see if we left.
        if (isProcessingBlockedContent) {
            // Check if the blocked app is still visible in ANY window
            if (!isBlockedContentVisible()) {
                onBlockedContentExited()
            }
            return
        }

        // --- DETECTION PHASE ---
        if (event == null || event.packageName == null) return
        val packageName = event.packageName.toString()

        // Filter: Only care about our target apps
        if (packageName != "com.google.android.youtube" && packageName != "com.instagram.android") {
            return
        }

        val rootNode = rootInActiveWindow ?: return

        // Check for "Brain Rot"
        if (packageName == "com.google.android.youtube" && isYouTubeBlocked) {
            if (detectYouTubeShorts(rootNode)) {
                onBlockedContentEntered(packageName)
            }
        } 
        else if (packageName == "com.instagram.android" && isInstagramBlocked) {
            if (detectInstagramReels(rootNode)) {
                onBlockedContentEntered(packageName)
            }
        }
    }

    /**
     * Called when "Brain Rot" is detected.
     * Switches service to High Alert Mode.
     */
    private fun onBlockedContentEntered(packageName: String) {
        if (isProcessingBlockedContent) return

        isProcessingBlockedContent = true
        currentBlockedPackage = packageName
        
        // 1. Expand Service Scope (Listen to ALL apps/launcher to detect exit)
        updateServiceConfig(listenToAll = true)

        // 2. Start Periodic Blocking Loop
        startPeriodicCheck()

        // 3. Immediate Block
        performBlock()
    }

    /**
     * Called when user leaves the content (Home screen, app switch, etc).
     * Reverts service to Battery Saver Mode.
     */
    private fun onBlockedContentExited() {
        isProcessingBlockedContent = false
        currentBlockedPackage = null
        
        // 1. Stop Loop
        stopPeriodicCheck()

        // 2. Restrict Service Scope (Save Battery)
        updateServiceConfig(listenToAll = false)
    }

    /**
     * The "Heartbeat" of the blocker.
     * Runs every second to ensure the user is kicked out if they are still there.
     */
    private fun startPeriodicCheck() {
        checkJob?.cancel()
        checkJob = serviceScope.launch {
            while (isActive && isProcessingBlockedContent) {
                if (isBlockedContentVisible()) {
                    performBlock()
                } else {
                    // Content no longer visible, exit loop
                    onBlockedContentExited()
                    break
                }
                delay(CHECK_INTERVAL)
            }
        }
    }

    private fun stopPeriodicCheck() {
        checkJob?.cancel()
    }

    private fun performBlock() {
        if (SystemClock.elapsedRealtime() - lastBackPressTime > BACK_PRESS_COOLDOWN) {
            performGlobalAction(GLOBAL_ACTION_BACK)
            lastBackPressTime = SystemClock.elapsedRealtime()
        }
    }

    /**
     * Checks all interactive windows (Notifications, Popups, App) to see if
     * the blocked content is actually visible to the user.
     */
    private fun isBlockedContentVisible(): Boolean {
        val targetPackage = currentBlockedPackage ?: return false
        
        // Iterate through all windows (Top to Bottom Z-Order)
        windows.forEach { window ->
            if (window.type == AccessibilityWindowInfo.TYPE_APPLICATION) {
                val root = window.root
                if (root != null && root.packageName == targetPackage) {
                    // If we found the app window, check if it's still showing "Brain Rot"
                    if (targetPackage == "com.google.android.youtube" && detectYouTubeShorts(root)) return true
                    if (targetPackage == "com.instagram.android" && detectInstagramReels(root)) return true
                }
            }
        }
        return false
    }

    // =========================================================
    // DYNAMIC CONFIGURATION (BATTERY SAVER)
    // =========================================================
    private fun updateServiceConfig(listenToAll: Boolean) {
        val info = serviceInfo ?: return
        
        if (listenToAll) {
            info.packageNames = null // Listen to everything (Home, Launcher, etc)
        } else {
            // Listen ONLY to targets
            info.packageNames = arrayOf("com.google.android.youtube", "com.instagram.android")
        }
        
        // CRITICAL: We need this flag to check "windows" list
        info.flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        serviceInfo = info
    }

    private fun refreshSettings() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
        isYouTubeBlocked = prefs.getBoolean("flutter.isYouTubeBlocked", true)
        isInstagramBlocked = prefs.getBoolean("flutter.isInstagramBlocked", true)
        
        // Keep "Alive" flag fresh
        if (!prefs.getBoolean("flutter.service_active", false)) {
            prefs.edit().putBoolean("flutter.service_active", true).apply()
        }
    }

    // =========================================================
    // NUCLEAR DETECTION STRATEGIES
    // =========================================================
    
    private fun detectInstagramReels(root: AccessibilityNodeInfo): Boolean {
        // LAYER 1: The "Right-Side" Rule (Geometric)
        val likes = root.findAccessibilityNodeInfosByText("Like")
        if (!likes.isNullOrEmpty()) {
            for (node in likes) {
                if (node.isVisibleToUser) {
                    val rect = Rect()
                    node.getBoundsInScreen(rect)
                    // If Like button is in the right 30% of screen -> It's a Reel
                    if (rect.left > (screenWidth * 0.7)) return true 
                }
            }
        }

        // LAYER 2: "Reels" Tab Selected
        val reelsTabs = root.findAccessibilityNodeInfosByText("Reels")
        if (!reelsTabs.isNullOrEmpty()) {
            for (node in reelsTabs) {
                if (node.isSelected || (node.parent != null && node.parent.isSelected)) return true
            }
        }

        // LAYER 3: "Reel by" Text
        if (!root.findAccessibilityNodeInfosByText("Reel by").isNullOrEmpty()) return true

        // LAYER 4: Legacy IDs
        if (hasId(root, "com.instagram.android:id/clips_video_container")) return true
        if (hasId(root, "com.instagram.android:id/clips_viewer_root")) return true
        
        return false
    }

    private fun detectYouTubeShorts(root: AccessibilityNodeInfo): Boolean {
        if (hasId(root, "com.google.android.youtube:id/reel_recycler")) return true
        if (hasId(root, "com.google.android.youtube:id/reel_player_view")) return true
        
        val shortsText = root.findAccessibilityNodeInfosByText("Shorts")
        if (!shortsText.isNullOrEmpty()) {
            if (hasText(root, "Like") || hasText(root, "Dislike")) return true
        }
        return false
    }

    private fun hasId(root: AccessibilityNodeInfo, id: String): Boolean {
        val nodes = root.findAccessibilityNodeInfosByViewId(id)
        return !nodes.isNullOrEmpty()
    }

    private fun hasText(root: AccessibilityNodeInfo, text: String): Boolean {
        val nodes = root.findAccessibilityNodeInfosByText(text)
        return !nodes.isNullOrEmpty()
    }

    override fun onInterrupt() {}
    
    override fun onUnbind(intent: android.content.Intent?): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", false).apply()
        serviceScope.cancel()
        return super.onUnbind(intent)
    }
}
