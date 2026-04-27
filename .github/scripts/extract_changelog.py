#!/usr/bin/env python3
"""从 CHANGELOG.md 提取指定版本的 Release Notes，输出到 stdout"""
import sys

version = sys.argv[1] if len(sys.argv) > 1 else ""

if not version:
    print("请查看 CHANGELOG.md 了解本版本变更内容。")
    sys.exit(0)

with open("CHANGELOG.md", "r", encoding="utf-8") as f:
    lines = f.readlines()

start = -1
end = len(lines)
for i, line in enumerate(lines):
    if start == -1 and line.startswith("## " + version):
        start = i + 1
    elif start != -1 and line.startswith("## "):
        end = i
        break

if start == -1:
    print("请查看 CHANGELOG.md 了解本版本变更内容。")
else:
    body = "".join(lines[start:end]).strip()
    print(body if body else "请查看 CHANGELOG.md 了解本版本变更内容。")
