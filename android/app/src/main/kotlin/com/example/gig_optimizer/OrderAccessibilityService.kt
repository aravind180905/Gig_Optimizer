package com.example.gig_optimizer

import android.accessibilityservice.AccessibilityService
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class MyAccessibilityService : AccessibilityService() {

    private var lastText = ""
    private var lastProcessedTime = 0L

    private var detectedFare = 0.0
    private var detectedDistance = 0.0

    // ✅ ALLOWED APPS ONLY
    private val allowedPackages = setOf(
        "com.ubercab.driver",
        "com.olacabs.oladriver",
        "in.swiggy.deliveryapp",
        "com.zomato.delivery",
        "com.rapido.rider",
        "com.ek_bharat.fleet",
        "com.zepto.rider",
        "id=in.shadowfax.gandalf"
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("SERVICE", "Accessibility Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        try {

            if (event == null) return

            // ✅ Reduce event flood
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastProcessedTime < 300) return
            lastProcessedTime = currentTime

            // ✅ Allow more useful events
            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED &&
                event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
                event.eventType != AccessibilityEvent.TYPE_VIEW_SCROLLED
            ) {
                return
            }

            // ✅ FIXED PACKAGE DETECTION
            val packageName = event.packageName?.toString()
                ?: rootInActiveWindow?.packageName?.toString()
                ?: return

            Log.d("APP_PKG", packageName)

            if (!allowedPackages.contains(packageName)) return

            // ✅ DELAY to allow UI to load
            Handler(Looper.getMainLooper()).postDelayed({

                val rootNode = rootInActiveWindow ?: return@postDelayed

                val builder = StringBuilder()
                collectAllText(rootNode, builder)

                val fullText = builder.toString().lowercase()

                Log.d("FULL_TEXT", fullText)

                if (fullText.isEmpty()) return@postDelayed
                if (fullText == lastText) return@postDelayed

                lastText = fullText

                extractData(fullText, packageName)

            }, 200)

        } catch (e: Exception) {
            Log.e("ACCESSIBILITY_CRASH", e.toString())
        }
    }

    override fun onInterrupt() {}

    // ✅ IMPROVED TEXT COLLECTION (VERY IMPORTANT)
    private fun collectAllText(node: AccessibilityNodeInfo?, builder: StringBuilder) {
        if (node == null) return

        try {
            node.text?.let {
                builder.append(it.toString()).append(" ")
            }

            node.contentDescription?.let {
                builder.append(it.toString()).append(" ")
            }

            for (i in 0 until node.childCount) {
                collectAllText(node.getChild(i), builder)
            }

        } catch (e: Exception) {
            Log.e("NODE_ERROR", e.message ?: "error")
        }
    }

  private fun extractData(fullText: String, packageName: String) {

    try {

        if (!fullText.contains("km") && !fullText.contains("₹")) return

        var fare = 0.0
        var firstMile = 0.0
        var lastMile = 0.0
        var totalMile = 0.0

        // =========================
        // 🟡 SWIGGY NEW UI LOGIC
        // =========================
        if (packageName == "in.swiggy.deliveryapp" &&
            fullText.contains("estimated earning")) {

            // 💰 Fare
            val fareMatch = Regex("estimated earning\\s*₹\\s*(\\d+(\\.\\d+)?)")
                .find(fullText)

            fare = fareMatch?.groupValues?.get(1)?.toDoubleOrNull() ?: 0.0

            // 📏 Distance
            val kmMatch = Regex("(\\d+(\\.\\d+)?)\\s*km")
                .find(fullText)

            lastMile = kmMatch?.groupValues?.get(1)?.toDoubleOrNull() ?: 0.0

            // ✅ Swiggy rule
            firstMile = 0.0
            totalMile = lastMile

        } else {

            // =========================
            // 💰 PRIORITY 1 → TOTAL EARNINGS
            // =========================
            val earningsMatches = Regex("total earnings\\s*₹\\s*(\\d+(\\.\\d+)?)")
                .findAll(fullText)
                .toList()

            if (earningsMatches.isNotEmpty()) {

                fare = earningsMatches.last().groupValues[1].toDoubleOrNull() ?: 0.0

            } else {

                // =========================
                // 💰 ₹ FALLBACK
                // =========================
                val fareMatches = Regex("₹\\s*(\\d+(\\.\\d+)?)")
                    .findAll(fullText)
                    .toList()

                if (fareMatches.isNotEmpty()) {

                    fare = if (packageName == "com.rapido.rider") {
                        fareMatches.first().groupValues[1].toDoubleOrNull() ?: 0.0
                    } else {
                        fareMatches.last().groupValues[1].toDoubleOrNull() ?: 0.0
                    }
                }
            }

            // =========================
            // 📏 DISTANCE LOGIC
            // =========================
            if (packageName == "com.rapido.rider") {

                val kmMatches = Regex("(\\d+(\\.\\d+)?)\\s*km")
                    .findAll(fullText)
                    .toList()

                if (kmMatches.size >= 2) {
                    firstMile = kmMatches.first().groupValues[1].toDoubleOrNull() ?: 0.0
                    lastMile = kmMatches.last().groupValues[1].toDoubleOrNull() ?: 0.0
                    totalMile = lastMile
                }

            } else {

                val firstMatch = Regex("(\\d+(\\.\\d+)?)\\s*km\\s*first mile")
                    .find(fullText)

                val lastMatch = Regex("(\\d+(\\.\\d+)?)\\s*km\\s*last mile")
                    .find(fullText)

                val totalMatch = Regex("(\\d+(\\.\\d+)?)\\s*km\\s*total mile")
                    .find(fullText)

                if (firstMatch != null && lastMatch != null) {

                    firstMile = firstMatch.groupValues[1].toDoubleOrNull() ?: 0.0
                    lastMile = lastMatch.groupValues[1].toDoubleOrNull() ?: 0.0

                    totalMile = if (totalMatch != null) {
                        totalMatch.groupValues[1].toDoubleOrNull() ?: lastMile
                    } else {
                        lastMile
                    }

                } else {

                    val kmMatches = Regex("(\\d+(\\.\\d+)?)\\s*km")
                        .findAll(fullText)
                        .toList()

                    if (kmMatches.isNotEmpty()) {
                        lastMile = kmMatches.last().groupValues[1].toDoubleOrNull() ?: 0.0
                        totalMile = lastMile
                    }
                }
            }
        }

        Log.d(
            "FINAL_RESULT",
            "PKG: $packageName | Fare: $fare | First: $firstMile | Last: $lastMile | Total: $totalMile"
        )

        // 🚀 SEND (NO CHANGE)
        if (fare > 0 && totalMile > 0) {
            sendToFlutter(
                fullText,
                fare,
                totalMile,
                firstMile,
                lastMile,
                packageName
            )
        }

    } catch (e: Exception) {
        Log.e("PARSE_ERROR", e.toString())
    }
}

    // ✅ SAFE EVENT CHANNEL SEND
    private fun sendToFlutter(
    text: String,
    fare: Double,
    totalKm: Double,
    firstKm: Double,
    lastKm: Double,
    packageName: String
) {
    Handler(Looper.getMainLooper()).post {

        MainActivity.eventSink?.success(
            mapOf(
                "text" to text,
                "fare" to fare,
                "total_km" to totalKm,
                "first_km" to firstKm,
                "last_km" to lastKm,
                "package_name" to packageName
            )
        )
    }
}
}