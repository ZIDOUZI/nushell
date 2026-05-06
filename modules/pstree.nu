export def main [
    root?: int  # 可选的起始进程PID，如果不提供则从PID 1开始
    --ascii = false
] {
    let all = (ps | select pid ppid name)
    let roots = if ($root | is-not-empty) {
        $root
    } else if ($nu.os-info.family == "windows") {
        $nu.pid
    } else {
        1
    }

    def build-tree [parent_pid: int] {
        $all | where ppid == $parent_pid | each {|child|
            {
                name: $child.name,
                pid: $child.pid,
                children: (build-tree $child.pid)
            }
        }
    }

    build-tree $roots
}
