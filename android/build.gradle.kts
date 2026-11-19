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
}

// file_selector_android (Favoriten-Import): Android-Lint stuerzt beim Analysieren
// von FileUtils.java im CommentDetector ab ("List.removeLast()", eine JDK-21-API;
// der Build laeuft mit JDK 17). Nur die Lint-Vital-Pruefung dieses Plugins aus,
// die der App bleibt.
subprojects {
    if (project.name == "file_selector_android") {
        tasks.configureEach {
            if (name.startsWith("lintVital")) enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
