package com.navware.nav_e

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.NodeClient
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Path for phone -> watch: one BLE-style frame per Wear message. */
const val WEAR_PATH_FRAME = "/nav/frame"

/** Path for watch -> phone: ACK or other messages. */
const val WEAR_PATH_MSG = "/nav/msg"

private const val TAG = "WearBridge"
private const val CHANNEL_WEAR = "org.navware.nav_e/wear"
private const val CHANNEL_WEAR_MESSAGES = "org.navware.nav_e/wear_messages"

class WearBridge(
    private val context: Context,
    private val binaryMessenger: io.flutter.plugin.common.BinaryMessenger,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val nodeClient: NodeClient by lazy { Wearable.getNodeClient(context) }
    private val messageClient: MessageClient by lazy { Wearable.getMessageClient(context) }

    private var messageEventSink: EventChannel.EventSink? = null
    private var messageListener: MessageClient.OnMessageReceivedListener? = null

    fun attach() {
        MethodChannel(binaryMessenger, CHANNEL_WEAR).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
        EventChannel(binaryMessenger, CHANNEL_WEAR_MESSAGES).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    messageEventSink = events
                    addMessageListener()
                }

                override fun onCancel(arguments: Any?) {
                    messageEventSink = null
                    removeMessageListener()
                }
            }
        )
    }

    fun detach() {
        MethodChannel(binaryMessenger, CHANNEL_WEAR).setMethodCallHandler(null)
        EventChannel(binaryMessenger, CHANNEL_WEAR_MESSAGES).setStreamHandler(null)
        removeMessageListener()
        executor.shutdown()
    }

    private fun addMessageListener() {
        if (messageListener != null) return
        messageListener = MessageClient.OnMessageReceivedListener { messageEvent ->
            if (messageEvent.path == WEAR_PATH_MSG) {
                val senderId = messageEvent.sourceNodeId
                val payload = messageEvent.data
                mainHandler.post {
                    val map = mapOf(
                        "deviceId" to senderId,
                        "payload" to payload,
                    )
                    messageEventSink?.success(map)
                }
            }
        }
        messageClient.addListener(messageListener!!)
    }

    private fun removeMessageListener() {
        messageListener?.let {
            messageClient.removeListener(it)
            messageListener = null
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getConnectedNodes" -> getConnectedNodes(result)
            "sendFrames" -> {
                val nodeId = call.argument<String>("nodeId")
                val framesRaw = call.argument<List<Any>>("frames")
                if (nodeId == null || framesRaw == null) {
                    result.error("INVALID_ARGS", "nodeId and frames required", null)
                    return
                }
                val frames = framesRaw.mapNotNull { item ->
                    when (item) {
                        is ByteArray -> item
                        is List<*> -> item.map { (it as? Number)?.toByte() ?: 0.toByte() }.toByteArray()
                        else -> null
                    }
                }
                if (frames.size != framesRaw.size) {
                    result.error("INVALID_ARGS", "frames must be list of byte arrays", null)
                    return
                }
                sendFrames(nodeId, frames, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun getConnectedNodes(result: MethodChannel.Result) {
        nodeClient.connectedNodes
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val nodes = task.result ?: emptyList()
                    val list = nodes.map { node ->
                        mapOf(
                            "id" to node.id,
                            "displayName" to node.displayName,
                        )
                    }
                    mainHandler.post { result.success(list) }
                } else {
                    Log.e(TAG, "getConnectedNodes failed", task.exception)
                    mainHandler.post { result.error("GET_NODES_FAILED", task.exception?.message, null) }
                }
            }
    }

    private fun sendFrames(
        nodeId: String,
        frames: List<ByteArray>,
        result: MethodChannel.Result,
    ) {
        executor.execute {
            try {
                val nodesResult = nodeClient.connectedNodes
                val nodes = try {
                    com.google.android.gms.tasks.Tasks.await(nodesResult)
                } catch (e: Exception) {
                    Log.e(TAG, "sendFrames get nodes failed", e)
                    mainHandler.post { result.error("SEND_FAILED", e.message, null) }
                    return@execute
                }
                if (!nodes.any { it.id == nodeId }) {
                    mainHandler.post { result.error("NODE_NOT_CONNECTED", "Node $nodeId not connected", null) }
                    return@execute
                }
                for (frame in frames) {
                    com.google.android.gms.tasks.Tasks.await(messageClient.sendMessage(nodeId, WEAR_PATH_FRAME, frame))
                }
                mainHandler.post { result.success(null) }
            } catch (e: Exception) {
                Log.e(TAG, "sendFrames failed", e)
                mainHandler.post { result.error("SEND_FAILED", e.message, null) }
            }
        }
    }
}
