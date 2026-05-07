# service.nu
# Go 微服务管理模块（api 与 rpc）
# 使用 job spawn 管理进程，通过 job list 获取实际 PID 并强制结束

# 所有受支持的服务名
def get-all-services [] {
    ["api", "rpc"]
}

# 启动单个服务
def start-one [name: string] {
    let state_file = ($env.PWD | path join "logs/.service-jobs.json")
    let state = if ($state_file | path exists) { open $state_file } else { {} }

    let entry = $state | get -o $name
    if ($entry | is-not-empty) and ($entry | get -o job_id | is-not-empty) {
        let job_id = $entry.job_id
        let job_exists = (job list | where id == $job_id | is-not-empty)
        if $job_exists {
            print $"服务 '($name)' 已在运行 \(job: ($job_id)\)"
            return
        }
    }

    print $"正在启动服务 '($name)'..."
    let job = if $name == "api" {
        job spawn -d $name { ^go run ./api }
    } else {
        # rpc 服务仍使用 ./srv 路径
        job spawn -d $name { ^go run ./srv }
    }

    let new_state = ($state | upsert $name { job_id: $job })
    $new_state | to json | save -f $state_file

    print $"服务 '($name)' 已启动 \(job ID: ($job)\)"
}

# 停止单个服务
def stop-one [name: string] {
    let state_file = ($env.PWD | path join "logs/.service-jobs.json")
    if not ($state_file | path exists) {
        print "未找到状态文件。"
        return
    }

    let state = open $state_file
    let entry = $state | get -o $name
    if ($entry | is-empty) or ($entry | get -o job_id | is-empty) {
        print $"服务 '($name)' 未在管理状态中。"
        return
    }

    let job_id = $entry.job_id
    let job_info = (job list | where id == $job_id)

    if ($job_info | is-empty) {
        print $"服务 '($name)' 的 job 已不存在，清理状态。"
        let new_state = ($state | reject $name)
        $new_state | to json | save -f $state_file
        return
    }

    # 从 job list 获取真实 PID（go run 可能启动了子进程，job list 返回的 pid 更可信）
    let pids = $job_info | get -o pid
    if ($pids | is-empty) {
        print $"无法获取服务 '($name)' 的进程 pid，尝试直接结束 job。"
        try { kill -f $job_id } catch { |e| print $"结束 job 失败: ($e.msg)" }
    } else {
        let pid_list = if ($pids | describe) == "list" { $pids } else { [$pids] }
        for pid in $pid_list {
            print $"正在停止服务 '($name)' 进程 \(pid: ($pid)\)"
            try { kill -f $pid } catch { |e| print $"无法结束进程 ($pid): ($e.msg)" }
        }
    }

    sleep 500ms
    let new_state = ($state | reject $name)
    $new_state | to json | save -f $state_file
    print $"服务 '($name)' 已停止。"
}

# 公开命令：启动
export def start [name?: string] {
    if ($name | is-empty) {
        for n in (get-all-services) { start-one $n }
    } else {
        if $name not-in (get-all-services) {
            error make { msg: $"服务名无效: ($name)，只能是 'api' 或 'rpc'" }
        }
        start-one $name
    }
}

# 公开命令：停止
export def stop [name?: string] {
    if ($name | is-empty) {
        for n in (get-all-services) { stop-one $n }
    } else {
        if $name not-in (get-all-services) {
            error make { msg: $"服务名无效: ($name)，只能是 'api' 或 'rpc'" }
        }
        stop-one $name
    }
}

# 公开命令：重启
export def restart [name?: string] {
    if ($name | is-empty) {
        for n in (get-all-services) {
            stop-one $n
            start-one $n
        }
    } else {
        if $name not-in (get-all-services) {
            error make { msg: $"服务名无效: ($name)，只能是 'api' 或 'rpc'" }
        }
        stop-one $name
        start-one $name
    }
}

# 公开命令：查看状态
export def status [] {
    let state_file = ($env.PWD | path join "logs/.service-jobs.json")
    if not ($state_file | path exists) {
        print "当前目录没有服务管理状态。"
        return
    }

    let state = open $state_file
    if ($state | columns | length) == 0 {
        print "当前无已记录的服务。"
        return
    }

    for name in (get-all-services) {
        let entry = $state | get -o $name
        if ($entry | is-not-empty) {
            let job_id = $entry.job_id
            let job_info = (job list | where id == $job_id)
            let running = ($job_info | is-not-empty)
            let status_text = if $running { "运行中" } else { "已停止" }
            let pid_info = if $running {
                let p = $job_info | get -o pid | first
                $"\(pid: ($p)\)"
            } else { "" }
            print $"($name): ($status_text) ($pid_info) \(job: ($job_id)\)"
        } else {
            print $"($name): 未管理"
        }
    }
}
