package com.twofit.twofit

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.twofit.twofit/toss_payment"
        private const val REQUEST_TOSS_PAYMENT = 22031
    }

    private var pendingPaymentResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPayment" -> startTossPayment(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startTossPayment(call: MethodCall, result: MethodChannel.Result) {
        if (pendingPaymentResult != null) {
            result.error("PAYMENT_IN_PROGRESS", "이미 진행 중인 결제가 있습니다.", null)
            return
        }
        val clientKey = call.argument<String>("clientKey").orEmpty()
        val customerKey = call.argument<String>("customerKey").orEmpty()
        val orderId = call.argument<String>("orderId").orEmpty()
        val orderName = call.argument<String>("orderName").orEmpty()
        val amount = call.argument<Number>("amount")?.toLong() ?: 0L
        val customerName = call.argument<String>("customerName").orEmpty()
        val customerEmail = call.argument<String>("customerEmail").orEmpty()
        val customerPhone = call.argument<String>("customerPhone").orEmpty()

        if (clientKey.isBlank() || customerKey.isBlank() || orderId.isBlank() || orderName.isBlank() || amount <= 0) {
            result.error("INVALID_PAYMENT_DATA", "결제 정보를 확인할 수 없습니다.", null)
            return
        }

        pendingPaymentResult = result
        val intent = Intent(this, TossPaymentActivity::class.java).apply {
            putExtra(TossPaymentActivity.EXTRA_CLIENT_KEY, clientKey)
            putExtra(TossPaymentActivity.EXTRA_CUSTOMER_KEY, customerKey)
            putExtra(TossPaymentActivity.EXTRA_ORDER_ID, orderId)
            putExtra(TossPaymentActivity.EXTRA_ORDER_NAME, orderName)
            putExtra(TossPaymentActivity.EXTRA_AMOUNT, amount)
            putExtra(TossPaymentActivity.EXTRA_CUSTOMER_NAME, customerName)
            putExtra(TossPaymentActivity.EXTRA_CUSTOMER_EMAIL, customerEmail)
            putExtra(TossPaymentActivity.EXTRA_CUSTOMER_PHONE, customerPhone)
        }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_TOSS_PAYMENT)
    }

    @Deprecated("Used to return result from the dedicated Toss payment activity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_TOSS_PAYMENT) return
        val callback = pendingPaymentResult ?: return
        pendingPaymentResult = null
        if (resultCode == Activity.RESULT_OK) {
            callback.success(
                mapOf(
                    "success" to true,
                    "paymentKey" to data?.getStringExtra(TossPaymentActivity.RESULT_PAYMENT_KEY),
                    "orderId" to data?.getStringExtra(TossPaymentActivity.RESULT_ORDER_ID),
                    "amount" to data?.getLongExtra(TossPaymentActivity.RESULT_AMOUNT, 0L),
                )
            )
        } else {
            callback.success(
                mapOf(
                    "success" to false,
                    "errorCode" to (data?.getStringExtra(TossPaymentActivity.RESULT_ERROR_CODE) ?: "PAYMENT_CANCELLED"),
                    "errorMessage" to (data?.getStringExtra(TossPaymentActivity.RESULT_ERROR_MESSAGE) ?: "결제가 취소되었거나 실패했습니다."),
                )
            )
        }
    }

    override fun onDestroy() {
        pendingPaymentResult?.error("ACTIVITY_DESTROYED", "결제 화면이 종료되었습니다.", null)
        pendingPaymentResult = null
        super.onDestroy()
    }
}
