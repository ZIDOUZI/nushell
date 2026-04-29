export def main [
  target: string          # 链接指向的目标路径
  link_name?: string      # 创建的链接名称，默认为当前目录下的目标文件名
  --symbolic (-s)         # 创建符号链接/软链接
  --force (-f)            # 若目标已存在，强制删除并覆盖
] {
  let final_link_name = $link_name | default ($target | path basename)

  if ($final_link_name | path exists) {
    if $force {
      rm -f $final_link_name
    } else {
      error make { msg: $"路径 '($final_link_name)' 已存在。使用 -f 参数以强制覆盖。" }
    }
  }

  let is_win = ($nu.os-info.name == "windows")
  let is_dir = (try { ($target | path type) == "dir" } catch { false })

  if not $is_win {
    if $symbolic {
      ^ln -s $target $final_link_name
    } else {
      ^ln $target $final_link_name
    }
  } else {
    let w_target = ($target | str replace -a '/' '\')
    let w_link = ($final_link_name | str replace -a '/' '\')

    if $symbolic {
      if $is_dir {
        ^cmd /c mklink /D $w_link $w_target
      } else {
        ^cmd /c mklink $w_link $w_target
      }
    } else {
      if $is_dir {
        error make { msg: "Windows 操作系统不支持为目录创建硬链接。" }
      } else {
        ^cmd /c mklink /H $w_link $w_target
      }
    }
  }
}
