export def shizuku [] {
  let libshizuku = "pm path moe.shizuku.privileged.api | cut -d: -f2 | sed 's#base.apk#lib/arm64/libshizuku.so#g'"
  try {
    ^adb shell echo "Starting Shizuku" | ignore
    ^adb shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh
    ^adb shell $"(^adb -d shell $libshizuku)"
  } catch {
    echo $"(ansi yellow)Using USB device...(ansi reset)"
    ^adb -d shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh
    ^adb -d shell $"(^adb -d shell $libshizuku)"
  }
}

export def package-path [package: string] {
  let smart_case = $package =~ "[A-Z]"
  ^adb shell pm list packages -3 | lines | find $package -i !$smart_case -n | each {|p|
    ^adb shell pm path ($p | split row : | last) | split row : | last
  }
}
