import com.android.build.gradle.BaseExtension
import java.io.File

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.0.2")
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            (extensions.findByName("android") as? BaseExtension)?.apply {
                compileSdkVersion(34)
                buildToolsVersion("34.0.0")
            }
        }
    }

    buildDir = File(rootProject.buildDir, name)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
