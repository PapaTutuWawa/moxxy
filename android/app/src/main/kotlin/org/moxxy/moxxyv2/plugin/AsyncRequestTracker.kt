package org.moxxy.moxxyv2.plugin

object AsyncRequestTracker {
    val requestTracker: MutableMap<Int, (Result<Any>) -> Unit> = mutableMapOf()
}
