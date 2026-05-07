# env.nu
#
# Installed by:
# version = "0.108.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

$env.EDITOR = "nvim"
# $env.LC_ALL = "zh_CN.UTF-8"
$env.LANG = "zh_CN.UTF-8"
# $env.config.edit_mode = "vi"

if ($env.NU_CONFIG_SHOW_BANNER? == 'false') {
  $env.config.show_banner = false
}

$env.TRANSIENT_PROMPT_COMMAND = {|| try { $" (starship module character) " } catch { "" } }
$env.NU_EXPERIMENTAL_OPTIONS = "native-clip"

