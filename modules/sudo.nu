def is-closure [] {
  return ($in | describe | str starts-with "closure")
}

# ==========================================
# 内部辅助函数：核心提权执行逻辑
# ==========================================
export def run-elevated [
    args: any,
    handler: closure,
] {
  let input_data = $in
  if ($args | is-empty) and ($input_data | is-empty) {
    print "USAGE: sudo <closure|string[]>"
    return
  }

  let target = $args.0
  let source_code = if ($target | is-closure) {
    $"do (view source $target)"
  } else if ($target | into string | which $in | get 0?.type?) != "external" {
    $args | each {|x| if ($x | is-closure) { view source $x } else { $x | into string } } | str join ' '
  } else if ($input_data | is-empty) {
    return (^sudo ...$args)
  } else {
    return ($input_data | ^sudo ...$args)
  }
  
  do $handler $input_data $source_code
}
# ==========================================
# 对外暴露的命令
# ==========================================

# 标准 sudo：自动识别闭包/字符串，使用 MsgPack 高速传输
export def main [...args: any] {
  $in | run-elevated $args {|data, source_code|
    # serialize and return raw binaries data into stdin
    let full_cmd = $"($source_code) | to msgpack | print -rn"
    if ($data | is-empty) {
      ^sudo nu -c $full_cmd
    } else {
      # read binaries from stdin and deserialize to original data
      $data | to msgpack | ^sudo nu --stdin -c $"from msgpack | ($full_cmd)"
    } | from msgpack
  }
}

# 大数据 sudo：专门用于处理海量表格（利用 Parquet + Dev Drive）
export def df [...args: any] {
  $in | run-elevated $args {|data, source_code|
    let tmp = $"E:/caches/sudo-cache-(random uuid).parquet"
    
    # 父进程动作：落盘到 Dev Drive
    $data | save -f $tmp
    
    # 子进程接收代码：读取临时文件, 执行并确保清理战场
    try {
      ^sudo nu -c $"open '($tmp)' | ($source_code)"
    } catch {|e|
      error make {msg: $"Sudo execution failed: ($e.msg)", debug: $e.debug, raw: $e.raw, render: $e.render, json: $e.json}
    } finally {
      rm -f $tmp
    }
  }
}
