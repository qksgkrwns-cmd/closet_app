allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    fun forceCompileSdk36() {
        val androidExt = extensions.findByName("android") ?: return
        try {
            val setCompileSdk = androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdk" && it.parameterTypes.size == 1
            }
            val setCompileSdkVersion = androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1
            }
            when {
                setCompileSdk != null -> setCompileSdk.invoke(androidExt, 36)
                setCompileSdkVersion != null -> setCompileSdkVersion.invoke(androidExt, 36)
            }
        } catch (_: Exception) {
            // Ignore modules that do not expose Android compileSdk setters.
        }
    }

    plugins.withId("com.android.application") { forceCompileSdk36() }
    plugins.withId("com.android.library") { forceCompileSdk36() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
