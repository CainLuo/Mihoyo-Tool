#!/bin/bash
# 启动原型预览服务器

cd "$(dirname "$0")"
echo "启动原型预览服务器..."
echo "请在浏览器中打开: http://localhost:8080"
echo "按 Ctrl+C 停止服务器"
python3 -m http.server 8080
