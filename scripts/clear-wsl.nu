#!/usr/bin/env nu

if $nu.os-info.name == "windows" { return }

def main [] {
    print "开始执行备份前系统清理任务...\n"

    # 1. 基础包缓存
    print ">> 1. 清理 Paru/Pacman 缓存"
    paru -Scc

    # 2. 孤儿包清理
    print "\n>> 2. 检查并清理孤儿包"
    # do -i 忽略 pacman 返回空值时的非零状态码，lines 将文本转为 Nushell 列表
    let orphans = (try { pacman -Qtdq } catch { "" } | lines)
    if ($orphans | is-empty) {
        print "当前系统整洁，未发现孤儿包。"
    } else {
        print $"发现孤儿包，开始清理: ($orphans | str join ' ')"
        ^sudo pacman -Rns ...$orphans
    }

    # 3. 开发工具链缓存
    print "\n>> 3. 清理开发构建缓存"
    
    # 停止 Rust sccache 服务
    # try { sccache --stop-server }

    # 定义需要强制删除的目录列表 (Rust 与 Gradle)
    let cache_dirs = [
        "~/.cache/sccache"
        "~/.cargo/registry"
        "~/.cargo/git"
        "~/.gradle/caches"
        "~/.gradle/daemon"
    ]
    
    # 展开路径并批量删除，do -i 确保目录不存在时不会报错中断
    $cache_dirs | path expand | each { |dir| 
        try { rm -rf $dir }
    }

    # 执行自带清理命令的工具 (Go, uv, bun)
    try { go clean -cache -modcache }
    try { uv cache clean }
    # try { bun pm cache rm }
    print "开发工具缓存清理完毕。"

    # 4. 系统日志与临时文件
    print "\n>> 4. 清理系统日志与临时目录"
    ^sudo journalctl --vacuum-time=50M
    
    # /tmp 包含受保护的文件，Nushell 自身的 rm 权限处理不如原生 bash 配合 sudo 干净
    ^sudo rm -rf /tmp/* /var/tmp/*

    print "\n>> 5. 清理系统socket"
    ^sudo rm -f /etc/pacman.d/gnupg/S.*
    ^sudo rm -f ~/.gnupg/S.*

    print "\n清理流程结束。请执行 `wsl --shutdown` 后再进行导出操作。"
}
