export def main [target: string] {
  let os = $nu.os-info.name

  if $os == "windows" {
    ^cmd /c start "" $target
  } else if $os == "macos" {
    ^open $target
  } else {
    ^xdg-open $target
  }
}
