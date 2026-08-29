package com.twofit.twofit

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.tosspayments.paymentsdk.PaymentWidget
import com.tosspayments.paymentsdk.model.AgreementStatus
import com.tosspayments.paymentsdk.model.AgreementStatusListener
import com.tosspayments.paymentsdk.model.PaymentCallback
import com.tosspayments.paymentsdk.model.TossPaymentResult
import com.tosspayments.paymentsdk.view.Agreement
import com.tosspayments.paymentsdk.view.PaymentMethod

class TossPaymentActivity : AppCompatActivity() {
    companion object {
        const val EXTRA_CLIENT_KEY = "toss_client_key"
        const val EXTRA_CUSTOMER_KEY = "toss_customer_key"
        const val EXTRA_ORDER_ID = "toss_order_id"
        const val EXTRA_ORDER_NAME = "toss_order_name"
        const val EXTRA_AMOUNT = "toss_amount"
        const val EXTRA_CUSTOMER_NAME = "toss_customer_name"
        const val EXTRA_CUSTOMER_EMAIL = "toss_customer_email"
        const val EXTRA_CUSTOMER_PHONE = "toss_customer_phone"

        const val RESULT_PAYMENT_KEY = "paymentKey"
        const val RESULT_ORDER_ID = "orderId"
        const val RESULT_AMOUNT = "amount"
        const val RESULT_ERROR_CODE = "errorCode"
        const val RESULT_ERROR_MESSAGE = "errorMessage"
    }

    private lateinit var paymentWidget: PaymentWidget
    private lateinit var paymentButton: Button
    private var resultDelivered = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val clientKey = intent.getStringExtra(EXTRA_CLIENT_KEY).orEmpty()
        val customerKey = intent.getStringExtra(EXTRA_CUSTOMER_KEY).orEmpty()
        val orderId = intent.getStringExtra(EXTRA_ORDER_ID).orEmpty()
        val orderName = intent.getStringExtra(EXTRA_ORDER_NAME).orEmpty()
        val amount = intent.getLongExtra(EXTRA_AMOUNT, 0L)
        if (clientKey.isBlank() || customerKey.isBlank() || orderId.isBlank() || orderName.isBlank() || amount <= 0) {
            finishWithFailure("INVALID_PAYMENT_DATA", "결제 정보를 확인할 수 없습니다.")
            return
        }

        val root = ScrollView(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(20), dp(20), dp(28))
        }
        root.addView(content)
        setContentView(root)

        content.addView(TextView(this).apply {
            text = "토스페이먼츠 결제"
            textSize = 20f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, dp(8))
        })
        content.addView(TextView(this).apply {
            text = "결제 금액 ${String.format("%,d", amount)}원"
            textSize = 16f
            setPadding(0, 0, 0, dp(16))
        })

        val paymentMethod = PaymentMethod(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
        }
        val agreement = Agreement(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
        }
        content.addView(paymentMethod)
        content.addView(agreement)

        paymentButton = Button(this).apply {
            text = "결제하기"
            isEnabled = false
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(16) }
        }
        content.addView(paymentButton)

        paymentWidget = PaymentWidget(
            activity = this,
            clientKey = clientKey,
            customerKey = customerKey,
        )
        paymentWidget.renderPaymentMethods(paymentMethod, amount)
        paymentWidget.renderAgreement(agreement)
        paymentWidget.addAgreementStatusListener(object : AgreementStatusListener {
            override fun onAgreementStatusChanged(agreementStatus: AgreementStatus) {
                runOnUiThread {
                    paymentButton.isEnabled = agreementStatus.agreedRequiredTerms
                }
            }
        })

        paymentButton.setOnClickListener {
            paymentButton.isEnabled = false
            try {
                paymentWidget.requestPayment(
                    paymentInfo = PaymentMethod.PaymentInfo(orderId = orderId, orderName = orderName),
                    paymentCallback = object : PaymentCallback {
                        override fun onPaymentSuccess(success: TossPaymentResult.Success) {
                            runOnUiThread {
                                finishWithSuccess(success.paymentKey, success.orderId, success.amount.toLong())
                            }
                        }

                        override fun onPaymentFailed(fail: TossPaymentResult.Fail) {
                            runOnUiThread {
                                finishWithFailure(fail.errorCode, fail.errorMessage)
                            }
                        }
                    },
                )
            } catch (_: Exception) {
                finishWithFailure("PAYMENT_WIDGET_ERROR", "결제 화면을 시작할 수 없습니다.")
            }
        }
    }

    private fun finishWithSuccess(paymentKey: String, orderId: String, amount: Long) {
        if (resultDelivered) return
        resultDelivered = true
        setResult(Activity.RESULT_OK, Intent().apply {
            putExtra(RESULT_PAYMENT_KEY, paymentKey)
            putExtra(RESULT_ORDER_ID, orderId)
            putExtra(RESULT_AMOUNT, amount)
        })
        finish()
    }

    private fun finishWithFailure(errorCode: String, message: String) {
        if (resultDelivered) return
        resultDelivered = true
        setResult(Activity.RESULT_CANCELED, Intent().apply {
            putExtra(RESULT_ERROR_CODE, errorCode)
            putExtra(RESULT_ERROR_MESSAGE, message)
        })
        finish()
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
