export def self [
  left_on: string,            # 左表用于 join 的列名
  right_on?: string,          # 右表用于 join 的列名 (省略则与 left_on 相同)
  --inner (-i),               # inner join (默认)
  --left (-l),                # left join
  --right (-r),               # right join
  --outer (-o),               # outer (full) join
  --suffix (-s): string = "_" # 重复列名后缀 (默认 "_")
  --prefix (-p): string = ""  # 重复列名前缀 (默认 "")
] {
  let tbl = $in

  # 右表列名默认与左表相同
  let ron = if ($right_on == null) { $left_on } else { $right_on }

  # 执行 join: 左表 = $tbl, 右表 = $tbl (自身)
  if $left {
    $tbl | join $tbl $left_on $ron --prefix $prefix --suffix $suffix --left
  } else if $right {
    $tbl | join $tbl $left_on $ron --prefix $prefix --suffix $suffix --right
  } else if $outer {
    $tbl | join $tbl $left_on $ron --prefix $prefix --suffix $suffix --outer
  } else {
    $tbl | join $tbl $left_on $ron --prefix $prefix --suffix $suffix
  }
}