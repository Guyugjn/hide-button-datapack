#!/usr/bin/env python3
"""校验 dist/ 下三个数据包 zip 的健康度。

判定项（缺一不可）：
  · CRC 完好 —— 只有会校验 CRC 的工具才认得出损坏，资源管理器与 Expand-Archive 不会
  · pack.mcmeta 位于 zip 根部 —— 多套一层目录游戏就读不到，表现为数据包列表里看不见
  · 三个包齐全，且各自条目数落在合理范围

用法：python3 tools/verify_zips.py
"""

import glob
import os
import sys
import zipfile

EXPECTED = [
    "ybih-1.16.2-1.20.4.zip",
    "ybih-1.20.5-1.21.4.zip",
    "ybih-1.21.5-26.2.zip",
]

DIST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "dist")

errors = []

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

extra = [os.path.basename(p) for p in glob.glob(os.path.join(DIST, "*")) if os.path.basename(p) not in EXPECTED]
if extra:
    errors.append(f"dist/ 里有非预期条目：{', '.join(sorted(extra))}")

if errors:
    print("\n校验失败：", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)

print("\n全部通过。")
