package `in`.hamari.chitfund.demo

import android.app.Activity
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.graphics.BitmapFactory
import android.view.WindowManager

/**
 * Visual-only homepage preview.
 * The supplied reference screenshot is displayed edge-to-edge so its colours,
 * shadows, texture, typography and spacing remain pixel-identical.
 * Buttons are intentionally not wired yet; this is the homepage design stage.
 */
class MainActivity : Activity() {
    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        )

        val image = ImageView(this).apply {
            setImageBitmap(BitmapFactory.decodeResource(resources, R.drawable.homepage_reference))
            scaleType = ImageView.ScaleType.FIT_XY
            contentDescription = "हमारा समूह - होम स्क्रीन"
        }
        setContentView(image)
    }
}
