package moe.azura.nhentai_app

import android.os.Environment
import android.content.*
import androidx.annotation.NonNull

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "azura.moe/paths").setMethodCallHandler {
        call, result ->
            if (call.method == "getDocumentDirectory") {
                result.success(
                    Environment
                    .getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_DOCUMENTS
                    ).getAbsolutePath()
                )
            } else {
                result.notImplemented()
            }
        }
    }
}
