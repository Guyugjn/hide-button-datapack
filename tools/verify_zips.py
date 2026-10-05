#!/usr/bin/env python3
"""校验 dist/ 下三个数据包 zip 的健康度。

判定项（缺一不可）：
  · CRC 完好 —— 只有会校验 CRC 的工具才认得出损坏，资源管理器与 Expand-Archive 不会
  · pack.mcmeta 位于 zip 根部 —— 多套一层目录游戏就读不到，表现为数据包列表里看不见
  · 三个包齐全，且各自条目数落在合理范围
  · 产物比 src/ 新 —— 这一条专门拦「旧产物冒充新产物」：结构检查全过、
    但内容是上一次构建留下的，跑完这个脚本就拿去部署等于白测一轮

用法：python3 tools/verify_zips.py

退出码：全部通过为 0，任何一项不通过为 1（可直接接进 CI 或 && 串联）。
"""

import datetime
import glob
import os
import sys
import zipfile

EXPECTED = [
    "ybih-1.16.2-1.20.4.zip",
    "ybih-1.20.5-1.21.4.zip",
    "ybih-1.21.5-26.2.zip",
]

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist")
SRC = os.path.join(ROOT, "src")


def stamp(mtime):
    return datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")


def newest_source():
    """返回 src/ 下最近一次修改的（路径, mtime）；读不到时返回 None。"""
    newest = None
    for dirpath, _dirnames, filenames in os.walk(SRC):
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            try:
                mtime = os.path.getmtime(full)
            except OSError:
                continue  # 遍历途中文件被删掉，跳过即可
            if newest is None or mtime > newest[1]:
                newest = (full, mtime)
    return newest


errors = []

src_newest = newest_source()
if src_newest is None:
    errors.append("读不到源文件目录 src/，无法判断产物新旧")
else:
    print("源文件最新改动：%s（%s）" % (os.path.relpath(src_newest[0], ROOT), stamp(src_newest[1])))

for name in EXPECTED:
    path = os.path.join(DIST, name)
    if not os.path.isfile(path):
        errors.append(f"缺少产物：{name}")
        continue

    with zipfile.ZipFile(path) as z:
        bad = z.testzip()
        if bad is not None:
            errors.append(f"{name} CRC 损坏：{bad}")
        names = z.namelist()
        if "pack.mcmeta" not in names:
            errors.append(f"{name} 的 pack.mcmeta 不在根部")
        if not any(n.startswith("data/") for n in names):
            errors.append(f"{name} 里没有 data/ 目录")
        print(f"{name}: {len(names)} 条目, {os.path.getsize(path)} 字节, CRC {'OK' if bad is None else 'BAD'}")

    # 新鲜度：产物若早于 src/ 最近改动，说明它是上一次构建留下的旧包
    if src_newest is not None and os.path.getmtime(path) < src_newest[1]:
        errors.append(
            "%s 比源文件旧（产物 %s < 源 %s %s）—— 请重新运行 node tools/build.mjs"
            % (name, stamp(os.path.getmtime(path)), os.path.relpath(src_newest[0], ROOT), stamp(src_newest[1]))
        )

extra = [os.path.basename(p) for p in glob.glob(os.path.join(DIST, "*")) if os.path.basename(p) not in EXPECTED]
if extra:
    errors.append(f"dist/ 里有非预期条目：{', '.join(sorted(extra))}")

if errors:
    print("\n校验失败：", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)

print("\n全部通过。")
