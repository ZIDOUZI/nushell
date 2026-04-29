export def port [port?: string] {
  let table_data = if ($nu.os-info.name == "windows") {
    ^netstat -ano | decode gbk | lines | find -r "TCP|UDP" --no-highlight | each {|line|
      let fileds = ($line | str trim | split row -r '\s+')
      if ($fileds | length) == 5 {
        { protocol: $fileds.0, local: $fileds.1, foreign: $fileds.2, state: $fileds.3, pid: $fileds.4 }
      } else {
        { protocol: $fileds.0?, local: $fileds.1?, foreign: $fileds.2?, state: "", pid: $fileds.3? }
      }
    }
  } else {
    ^lsof -nP -i | lines | skip 1 | each {|line|
      let fileds = ($line | split row -r '\s+')
      {
        protocol: ($fileds | get 7? | default ""),
        local: ($fileds | get 8? | default "unknown"),
        foreign: "",
        state: ($fileds | get 9? | default "" | str replace "(" "" | str replace ")" ""),
        pid: ($fileds | get 1)
      }
    }
  }
  
  if ($port | is-empty) {
    $table_data
  } else {
    $table_data | where local =~ $":($port)\(?:\b|$\)"
  }
}
