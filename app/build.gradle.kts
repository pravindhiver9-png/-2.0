plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "in.hamari.chitfund.demo"
    compileSdk = 35

    defaultConfig {
        applicationId = "in.hamari.chitfund.demo"
        minSdk = 23
        targetSdk = 28
        versionCode = 1
        versionName = "1.0"
    }
}
