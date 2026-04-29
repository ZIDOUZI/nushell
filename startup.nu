source completion/btm.nu
source completion/winget.nu

const init_tools = {
    starship: "starship init nu"
    zoxide: "zoxide init nushell"
    atuin: "atuin init nu"
    carapace: "carapace _carapace nushell"
    tree-sitter: "tree-sitter complete -s nushell"
    desktop-ini: "desktop-ini completion nu-shell"
    uv: "uv --generate-shell-completion nushell"
    uvx: "uvx --generate-shell-completion nushell"
    # mise: "mise activate nu"
    # openfang: "openfang completion"
}

let autoload_dir = $nu.data-dir | path join "vendor/autoload"
let source_lines = []

if not ($autoload_dir | path exists) {
    mkdir $autoload_dir
}

$init_tools | transpose name cmd | any {|elt|
  let file_path = $autoload_dir | path join $".($elt.name).nu"

  if not ($file_path | path exists) {
    let result = ^nu -c $elt.cmd | complete
    if $result.exit_code == 0 {
      $result.stdout | save -f $file_path
    }
    $result.exit_code == 0
  }
} | if $in {
  print "Need to restart a new shell to get full completion and integration"
}

