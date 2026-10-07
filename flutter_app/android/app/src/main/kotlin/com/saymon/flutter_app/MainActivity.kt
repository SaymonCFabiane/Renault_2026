package com.saymon.flutter_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    // Uma thread só para a compressão: os quadros já chegam em sequência e o app descarta os excedentes.
    private val compressor = Executors.newSingleThreadExecutor()
    private val principal = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tracepro/jpeg").setMethodCallHandler { call, result ->
            if (call.method != "paraJpeg") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val args = call.arguments as Map<*, *>
            compressor.execute {
                try {
                    val r = paraJpeg(args)
                    principal.post { result.success(r) }
                } catch (e: Exception) {
                    principal.post { result.error("JPEG", e.message, null) }
                }
            }
        }
    }

    override fun onDestroy() {
        compressor.shutdownNow()
        super.onDestroy()
    }

    /**
     * Quadro da câmera (NV21 em um plano, ou YUV_420_888 em três) → JPEG.
     * Recorta o centro em 4:3 e, se for maior que larguraMax, reduz para 640×480.
     */
    private fun paraJpeg(args: Map<*, *>): Map<String, Any> {
        val w = args["largura"] as Int
        val h = args["altura"] as Int
        val planos = (args["planos"] as List<*>).map { it as ByteArray }
        val linhas = (args["linhas"] as List<*>).map { it as Int }
        val pixels = (args["pixels"] as List<*>).map { it as Int }
        val qualidade = args["qualidade"] as Int
        val larguraMax = args["larguraMax"] as Int

        val nv21 = if (planos.size == 1) planos[0] else yuv420ParaNv21(w, h, planos, linhas, pixels)

        // Recorte central 4:3 (coordenadas pares, exigência do NV21).
        var cw = w
        var ch = h
        if (w * 3 > h * 4) cw = (h * 4 / 3) and 1.inv() else if (w * 3 < h * 4) ch = (w * 3 / 4) and 1.inv()
        val left = ((w - cw) / 2) and 1.inv()
        val top = ((h - ch) / 2) and 1.inv()

        val saida = ByteArrayOutputStream()
        YuvImage(nv21, ImageFormat.NV21, w, h, null).compressToJpeg(Rect(left, top, left + cw, top + ch), qualidade, saida)
        var jpeg = saida.toByteArray()

        if (cw > larguraMax) {
            val alvoW = larguraMax
            val alvoH = larguraMax * 3 / 4
            val original = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size)
            val reduzido = Bitmap.createScaledBitmap(original, alvoW, alvoH, true)
            val s2 = ByteArrayOutputStream()
            reduzido.compress(Bitmap.CompressFormat.JPEG, qualidade, s2)
            original.recycle()
            reduzido.recycle()
            jpeg = s2.toByteArray()
            cw = alvoW
            ch = alvoH
        }
        return mapOf("jpeg" to jpeg, "largura" to cw, "altura" to ch)
    }

    /** Monta NV21 (Y + VU intercalados) a partir dos três planos, respeitando os strides. */
    private fun yuv420ParaNv21(w: Int, h: Int, planos: List<ByteArray>, linhas: List<Int>, pixels: List<Int>): ByteArray {
        val (y, u, v) = planos
        val nv21 = ByteArray(w * h * 3 / 2)
        var pos = 0
        val yLinha = linhas[0]
        if (yLinha == w) {
            System.arraycopy(y, 0, nv21, 0, w * h)
            pos = w * h
        } else {
            for (linha in 0 until h) {
                System.arraycopy(y, linha * yLinha, nv21, pos, w)
                pos += w
            }
        }
        val uvLinha = linhas[1]
        val uvPixel = pixels[1]
        for (linha in 0 until h / 2) {
            for (col in 0 until w / 2) {
                val i = linha * uvLinha + col * uvPixel
                nv21[pos++] = v[i]
                nv21[pos++] = u[i]
            }
        }
        return nv21
    }
}
