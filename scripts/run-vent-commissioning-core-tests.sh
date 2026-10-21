#!/bin/bash
# Root-owned pure Kotlin/JUnit execution only; no Gradle, Android or native process.
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
if [ "$#" -ne 2 ]; then echo 'Usage: bash scripts/run-vent-commissioning-core-tests.sh /absolute/java /external/result.jar' >&2; exit 2; fi
shk_java="$1"
shk_output="$2"
test -x "$shk_java"
shk_cache='/Volumes/SSK SSD/Kamilunavo/Cache/Gradle/caches/modules-2/files-2.1'
shk_jar() {
  local matches=( "$shk_cache/$1/$2/$3/"*"/$2-$3.jar" )
  if [ "${#matches[@]}" -ne 1 ] || [ ! -f "${matches[0]}" ]; then echo "Missing or ambiguous cached dependency $1:$2:$3" >&2; return 2; fi
  printf '%s' "${matches[0]}"
}
shk_compiler="$(shk_jar org.jetbrains.kotlin kotlin-compiler-embeddable 2.3.21)"
shk_stdlib="$(shk_jar org.jetbrains.kotlin kotlin-stdlib 2.3.21)"
shk_script="$(shk_jar org.jetbrains.kotlin kotlin-script-runtime 2.3.21)"
shk_reflect="$(shk_jar org.jetbrains.kotlin kotlin-reflect 1.6.10)"
shk_daemon="$(shk_jar org.jetbrains.kotlin kotlin-daemon-embeddable 2.3.21)"
shk_coroutines="$(shk_jar org.jetbrains.kotlinx kotlinx-coroutines-core-jvm 1.8.0)"
shk_trove="$(shk_jar org.jetbrains.intellij.deps trove4j 1.0.20200330)"
shk_annotations="$(shk_jar org.jetbrains annotations 13.0)"
shk_junit="$(shk_jar junit junit 4.13.2)"
shk_hamcrest="$(shk_jar org.hamcrest hamcrest-core 1.3)"
shk_json="$(shk_jar org.json json 20240303)"
shk_compiler_cp="$shk_compiler:$shk_stdlib:$shk_script:$shk_reflect:$shk_daemon:$shk_coroutines:$shk_trove:$shk_annotations"
shk_test_cp="$shk_stdlib:$shk_annotations:$shk_junit:$shk_hamcrest:$shk_json"
"$shk_java" -Xmx384m -XX:MaxMetaspaceSize=192m -XX:+UseSerialGC -cp "$shk_compiler_cp" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
  -no-stdlib -no-reflect -jvm-target 17 -classpath "$shk_test_cp" -d "$shk_output" \
  android/app/src/main/java/de/kamilunavo/shk/VentCommissioning.kt \
  android/app/src/main/java/de/kamilunavo/shk/VentCommissioningArchive.kt \
  android/app/src/test/java/de/kamilunavo/shk/VentCommissioningTest.kt
"$shk_java" -Xmx128m -XX:+UseSerialGC -cp "$shk_output:$shk_test_cp" org.junit.runner.JUnitCore de.kamilunavo.shk.VentCommissioningTest
