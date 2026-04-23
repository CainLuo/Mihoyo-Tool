# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- **Every edit to a file must end with an import cleanup pass**: scan all `import` statements and remove any that are no longer referenced in the file after your changes.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 3.1 整理代码后的影响验证

**凡是删除或修改现有代码的行为（不限于整理），必须在改完后主动验证不影响原有逻辑。**

触发条件（满足任意一条就必须验证）：

- 删除装饰器（如 `@ObservedV2`、`@Trace`、`@State`）
- 删除方法或字段
- 修改方法签名（参数增减、类型变更）
- 将逻辑从一个文件迁移到另一个文件
- 删除中间层文件（如只有 re-export 的文件）
- 修改 import 路径

验证步骤：

1. **搜索所有调用方**：用 `grepSearch` 找出被修改的类/方法/字段的所有引用
2. **判断影响**：逐一确认每个调用方是否依赖被删除/修改的行为
3. **说明结论**：在回复中明确写出"不影响，原因是……"或"有影响，已同步修改……"

**禁止**在没有完成上述验证的情况下直接提交改动。

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**For large tasks (more than ~5 files to read or write):**

- Break into batches of 3–5 files maximum per round
- After each batch, report what was done and what remains
- This allows the user to resume from the last completed batch if execution stalls

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## 5. Response Style

**Never reply with only "Understood" or acknowledgment phrases without action or content.**

- If the message is a task → start doing it immediately, no preamble.
- If the message is information/context → acknowledge briefly AND state what you'll do next, or ask a specific question if genuinely unclear.
- If the message is a question → answer it directly.
- All responses must be in **Simplified Chinese (简体中文)** unless the user writes in another language.

Banned openers: "Understood", "Got it", "Sure", "Of course", "Certainly", "I'll help you with that".
