# config.nu
#
# Installed by:
# version = "0.108.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

source startup.nu
source aliases.nu
source platform/windows.nu
source platform/linux.nu

use modules/network.nu
use modules/sudo.nu
use modules/start.nu
use modules/terminal.nu
use modules/adb.nu
use modules/confirm.nu
use modules/ln.nu
use modules/ps.nu
use modules/join.nu

$env.config = ($env.config? | default {})

$env.config.color_config = $env.config.color_config? | default {} | merge {
  # shape_externalarg: { fg: cyan }
  # shape_filepath: { fg: green, attr: u }
  # shape_directory: { fg: green, attr: u }
  filesize: {|x| if $x == 0b { 'dark_gray' } else { 'cyan' } }
}
$env.config.render_right_prompt_on_last_line = true
$env.config.highlight_resolved_externals = true
$env.config.filesize.unit = "binary"

# disable osc633 since it is not working in vscodium
$env.config.shell_integration.osc633 = false

def swap-bak [file: path] {
  let bak = $"($file).bak"

  if not ($file | path exists) {
    error make {msg: $"原始文件 ($file) 不存在"}
  }
  if not ($bak | path exists) {
    error make {msg: $"备份文件 ($bak) 不存在"}
  }

  let tmp = (mktemp)
  mv $file $tmp
  mv $bak $file
  mv $tmp $bak
}

if not (which fastfetch | is-empty) and ($env.TERM_PROGRAM? != "vscode") and not $nu.is-interactive {
  $env.config.show_banner = false
  
  if $nu.os-info.name == "windows" {
    # return
    # TODO)): fix fastfetch can't find image magick library error.
    fastfetch -c E:/configurations/fastfetch.jsonc # --raw E:/configurations/fastfetch/togawa-sakiko.six
  } else {
    fastfetch --logo-type (terminal image-protocol | default "auto")
  }
}
