export def main [msg: string = "Are you sure?"] {
  let answer = input $"(ansi yellow)($msg) [y/N]: (ansi reset)" | str trim | str downcase
  return ($answer == "y")
}
