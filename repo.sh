#!/usr/bin/env bash
# xmake #6404 最小复现驱动脚本
# 对每个变体: configure 一次 → 连续两次 xmake build -vDr → 检查第二次构建的编译命令行里
#             on_load/on_check 动态添加的 -DFOO6404 是否还在。
#
# 判定:
#   REPRODUCED  : 第一次 build 有 flag, 第二次丢了   (bug 存在, issue #6404 复现)
#   KEPT        : 两次 build 都有 flag               (该变体未触发问题)
#   BROKEN      : 第一次 build 就失败/没 flag         (变体本身有问题, 结果无效)
#
# 退出码: 至少一个变体 REPRODUCED → 0; 否则 → 1
# (即: CI 红灯 = 上游已修复或环境变化; 绿灯 = bug 仍存在, 符合预期)
set -u

export XMAKE_COLORTERM=nocolor
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIANTS_DIR="$SCRIPT_DIR/variants"
FLAG="FOO6404"
STATIC_FLAG="funroll-loops"   # 静态 add_cxflags 的对照组 flag (仅 V1 有)

declare -a NAMES RESULT RC1 RC2 IN1 IN2

run_variant() {
    local name="$1"
    local dir="$VARIANTS_DIR/$name"
    cd "$dir" || return 1
    rm -rf build .xmake

    # configure 一次 (对应原始场景的 ./configure → xmake f)
    xmake f -c -m releasedbg > configure.log 2>&1
    local cfgrc=$?

    xmake build -vDr hello > build1.log 2>&1
    local r1=$?
    xmake build -vDr hello > build2.log 2>&1
    local r2=$?

    local f1 f2 s1 s2
    grep -q -- "-$FLAG" build1.log && f1=yes || f1=no
    grep -q -- "-$FLAG" build2.log && f2=yes || f2=no
    grep -q -- "-$STATIC_FLAG" build1.log && s1=yes || s1=no
    grep -q -- "-$STATIC_FLAG" build2.log && s2=yes || s2=no

    local verdict
    if [ "$cfgrc" -ne 0 ]; then
        verdict="BROKEN(configure失败)"
    elif [ "$r1" -ne 0 ]; then
        verdict="BROKEN(build1失败)"
    elif [ "$f1" = "no" ]; then
        verdict="BROKEN(build1就没flag)"
    elif [ "$f2" = "no" ]; then
        verdict="REPRODUCED"
    else
        verdict="KEPT"
    fi
    [ "$r2" -ne 0 ] && verdict="$verdict+build2失败"

    NAMES+=("$name"); RESULT+=("$verdict"); RC1+=("$r1"); RC2+=("$r2")
    IN1+=("$f1"); IN2+=("$f2")
    printf '  static-flag(-funroll-loops): build1=%s build2=%s\n' "$s1" "$s2" > "static_flag_check.txt"
    printf '[%s] %s (rc1=%s flag1=%s, rc2=%s flag2=%s)\n' "$name" "$verdict" "$r1" "$f1" "$r2" "$f2"
}

echo "=== xmake $(xmake --version | head -1 | grep -oE 'v[0-9][^ ,]*') / issue #6404 minimal repro ==="
any_repro=0
for v in onload_full onload_min onload_noio oncheck; do
    run_variant "$v"
    [[ "${RESULT[-1]}" == REPRODUCED* ]] && any_repro=1
done

echo
echo "================= 判定汇总 ================="
for i in "${!NAMES[@]}"; do
    printf '%-14s %-28s (build1: rc=%s flag=%s | build2: rc=%s flag=%s)\n' \
        "${NAMES[$i]}" "${RESULT[$i]}" "${RC1[$i]}" "${IN1[$i]}" "${RC2[$i]}" "${IN2[$i]}"
done
echo "============================================"
echo "REPRODUCED = 第一次build有 -D$FLAG, 第二次 build -r 后丢失 (issue #6404)"
echo "oncheck 变体预期为 KEPT (对照组, waruqi 建议的 on_check 方案)"

if [ "$any_repro" -eq 1 ]; then
    echo
    echo ">>> 复现成功: bug 仍存在于当前 xmake"
    exit 0
else
    echo
    echo ">>> 未复现: 当前 xmake 上没有变体触发 flag 丢失"
    exit 1
fi

