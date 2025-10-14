package com.example.Xnd

import io.flutter.embedding.android.FlutterActivity
import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.os.Build
import android.os.Bundle
import android.util.Base64
import android.util.Log
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 카카오 로그인 키 해시 출력 (디버그용)
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            signatures?.forEach { signature ->
                val md = MessageDigest.getInstance("SHA-1")
                md.update(signature.toByteArray())
                val keyHash = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
                Log.d("KAKAO_KEY_HASH", "Key Hash: $keyHash")
            }
        } catch (e: Exception) {
            Log.e("KAKAO_KEY_HASH", "Error getting key hash", e)
        }
    }
}
