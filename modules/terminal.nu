export def type []: nothing -> string {
  if ('WT_SESSION' in $env) {
    return "WindowsTerminal"
  } 
  
  if ('ALACRITTY_WINDOW_ID' in $env) or ('ALACRITTY_LOG' in $env) {
    return "Alacritty"
  } 
  
  if ('KITTY_WINDOW_ID' in $env) {
    return "Kitty"
  } 
  
  if ('TMUX' in $env) {
    return "Tmux"
  }

  let term_program = ($env | get TERM_PROGRAM?)
  if ($term_program != null) {
    return $term_program
  }

  let term = ($env | get TERM?)
  if ($term != null) {
    return $term
  }

  return "Unknown"
}

export def image-protocol []: nothing -> string {
  match (type | str downcase) {
    "windowsterminal" | "xterm" | "foot" => "sixel"
    "iterm2" => "iterm"
    "kitty" | "konsole" | "ghostty" | "wezterm" => "kitty"
    _ => null
  }
}
