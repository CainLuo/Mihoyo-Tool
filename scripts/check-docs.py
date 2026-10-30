import os
import sys

# 获取当前正在处理的文档（通过 vibe-loop 传递的环境变量或参数）
# 这里我们假设你手动指定了文件，或者遍历 docs
current_doc = os.environ.get("VIBE_CURRENT_FILE", "")

if not current_doc:
    print("未指定当前正在校验的文档。")
    sys.exit(1)

# 简单的防呆校验：检查文档是否被修改过（或者检查是否有对比代码的痕迹）
# 实际场景中，你可以写正则表达式，检查文档里是否含有对应的代码签名
with open(current_doc, "r", encoding="utf-8") as f:
    content = f.read()

# 比如要求文档中必须包含 "Verified-by-AI" 标记，或者比对特定代码块是否一致
if "【已核对代码一致性】" not in content:
    print(f"❌ 校验失败：文档 {current_doc} 中未找到代码比对确认标记。请仔细核对代码并补充说明。")
    sys.exit(1)

print(f"✅ 校验通过：{current_doc} 已确认与代码一致。")
sys.exit(0)
