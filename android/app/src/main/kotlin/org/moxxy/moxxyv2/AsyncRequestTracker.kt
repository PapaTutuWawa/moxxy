package org.moxxy.moxxyv2

object AsyncRequestTracker {
    val requestTracker: MutableMap<Int, (Result<Any>) -> Unit> = mutableMapOf()
}