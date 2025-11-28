buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // La línea de Android ya debe estar ahí, no la borres si existe:
        classpath("com.android.tools.build:gradle:8.2.1") 
        
        // 👇 ESTA ES LA LÍNEA NUEVA CORREGIDA (Con paréntesis y comillas dobles):
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ... (El resto del archivo, como 'rootProject.buildDir', déjalo igual)
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
