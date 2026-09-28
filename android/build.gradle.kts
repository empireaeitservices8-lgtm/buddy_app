allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val buildDirFile = File(rootProject.projectDir.parentFile, "build")
rootProject.layout.buildDirectory.set(buildDirFile)

subprojects {
    val subprojectBuildDir = File(buildDirFile, project.name)
    project.layout.buildDirectory.set(subprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
