export def modules [] {
  let os = $nu.os-info.name

  if $os == "windows" {
    ^tasklist /M /FO CSV /NH | from csv --noheaders
    | rename name pid modules | into int pid | each {|row|
      let mods = if $row.modules == "N/A" { [] } else {
        $row.modules | split row "," | str trim
      }
      { name: ($row.name | str trim), pid: $row.pid, modules: $mods }
    } | where {|r| not ($r.modules | is-empty)}
  } else {
    let lsof_output = (^lsof -n -w e> /dev/null | lines | where $it =~ '\.(so|dylib)')

    $lsof_output | each {|line|
      let fields = ($line | split words)
      { 
        name: $fields.0, 
        pid: ($fields.1 | into int), 
        module: ($fields | last) 
      }
    } | group-by pid | values | each {|grp|
      { 
        name: $grp.0.name, 
        pid: $grp.0.pid, 
        modules: ($grp.module | uniq) 
      }
    }
  }
}
