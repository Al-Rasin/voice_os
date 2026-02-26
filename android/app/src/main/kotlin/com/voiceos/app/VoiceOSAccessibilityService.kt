package com.voiceos.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class VoiceOSAccessibilityService : AccessibilityService() {

    companion object {
        var instance: VoiceOSAccessibilityService? = null
        var isRunning: Boolean = false
    }

    private var currentPackageName: String = ""
    private var cachedNodes: MutableList<AccessibilityNodeInfo> = mutableListOf()

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isRunning = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.packageName?.let { currentPackageName = it.toString() }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        isRunning = false
    }

    fun getScreenContent(): Map<String, Any?> {
        val root = rootInActiveWindow ?: return mapOf("error" to "No window available")
        val nodes = mutableListOf<Map<String, Any?>>()
        cachedNodes.clear()
        traverseNode(root, nodes, 0)
        return mapOf(
            "packageName" to currentPackageName,
            "nodes" to nodes
        )
    }

    private fun traverseNode(node: AccessibilityNodeInfo, nodes: MutableList<Map<String, Any?>>, depth: Int) {
        if (depth > 10 || nodes.size >= 40) return

        val isInteractive = node.isClickable || node.isScrollable || node.isEditable || node.isFocused
        val hasText = !node.text.isNullOrBlank() || !node.contentDescription.isNullOrBlank()

        if (isInteractive || hasText) {
            val rect = Rect()
            node.getBoundsInScreen(rect)
            cachedNodes.add(node)
            nodes.add(mapOf(
                "index" to (cachedNodes.size - 1),
                "className" to (node.className?.toString() ?: ""),
                "text" to (node.text?.toString()?.take(100) ?: ""),
                "contentDescription" to (node.contentDescription?.toString()?.take(100) ?: ""),
                "viewId" to (node.viewIdResourceName ?: ""),
                "bounds" to mapOf("left" to rect.left, "top" to rect.top, "right" to rect.right, "bottom" to rect.bottom),
                "isClickable" to node.isClickable,
                "isScrollable" to node.isScrollable,
                "isEditable" to node.isEditable,
                "isFocused" to node.isFocused,
                "isChecked" to node.isChecked,
                "isEnabled" to node.isEnabled,
                "isSelected" to node.isSelected,
                "depth" to depth
            ))
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            traverseNode(child, nodes, depth + 1)
        }
    }

    // Gesture execution methods
    fun executeTap(x: Int, y: Int): Boolean {
        val path = Path()
        path.moveTo(x.toFloat(), y.toFloat())

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 50))
            .build()

        return dispatchGesture(gesture, null, null)
    }

    fun executeTapNode(nodeIndex: Int): Boolean {
        if (nodeIndex < 0 || nodeIndex >= cachedNodes.size) return false
        val node = cachedNodes[nodeIndex]
        val rect = Rect()
        node.getBoundsInScreen(rect)
        val centerX = (rect.left + rect.right) / 2
        val centerY = (rect.top + rect.bottom) / 2
        return executeTap(centerX, centerY)
    }

    fun executeLongPress(x: Int, y: Int): Boolean {
        val path = Path()
        path.moveTo(x.toFloat(), y.toFloat())

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 1000))
            .build()

        return dispatchGesture(gesture, null, null)
    }

    fun executeSwipe(startX: Int, startY: Int, endX: Int, endY: Int, duration: Long = 300): Boolean {
        val path = Path()
        path.moveTo(startX.toFloat(), startY.toFloat())
        path.lineTo(endX.toFloat(), endY.toFloat())

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, duration))
            .build()

        return dispatchGesture(gesture, null, null)
    }

    fun swipeUp(): Boolean {
        val metrics = resources.displayMetrics
        val centerX = metrics.widthPixels / 2
        val startY = (metrics.heightPixels * 0.7).toInt()
        val endY = (metrics.heightPixels * 0.3).toInt()
        return executeSwipe(centerX, startY, centerX, endY)
    }

    fun swipeDown(): Boolean {
        val metrics = resources.displayMetrics
        val centerX = metrics.widthPixels / 2
        val startY = (metrics.heightPixels * 0.3).toInt()
        val endY = (metrics.heightPixels * 0.7).toInt()
        return executeSwipe(centerX, startY, centerX, endY)
    }

    fun swipeLeft(): Boolean {
        val metrics = resources.displayMetrics
        val centerY = metrics.heightPixels / 2
        val startX = (metrics.widthPixels * 0.8).toInt()
        val endX = (metrics.widthPixels * 0.2).toInt()
        return executeSwipe(startX, centerY, endX, centerY)
    }

    fun swipeRight(): Boolean {
        val metrics = resources.displayMetrics
        val centerY = metrics.heightPixels / 2
        val startX = (metrics.widthPixels * 0.2).toInt()
        val endX = (metrics.widthPixels * 0.8).toInt()
        return executeSwipe(startX, centerY, endX, centerY)
    }

    fun executeSetText(nodeIndex: Int, text: String): Boolean {
        if (nodeIndex < 0 || nodeIndex >= cachedNodes.size) return false
        val node = cachedNodes[nodeIndex]
        if (!node.isEditable) return false

        val arguments = Bundle()
        arguments.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        return node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    // Global actions
    fun pressBack(): Boolean = performGlobalAction(GLOBAL_ACTION_BACK)
    fun pressHome(): Boolean = performGlobalAction(GLOBAL_ACTION_HOME)
    fun pressRecents(): Boolean = performGlobalAction(GLOBAL_ACTION_RECENTS)
    fun openNotifications(): Boolean = performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
    fun openQuickSettings(): Boolean = performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
    fun takeScreenshot(): Boolean = performGlobalAction(GLOBAL_ACTION_TAKE_SCREENSHOT)
}
