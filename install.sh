#!/usr/bin/env bash
set -euo pipefail

EMMA_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_SKILLS_DIR="${HOME}/.hermes/skills"
INSTALLED=0
SKIPPED=0

echo "📦 部署 Emma Skills 到 Hermes..."
echo "   来源: ${EMMA_SKILLS_DIR}/skills"
echo "   目标: ${HERMES_SKILLS_DIR}/"
echo ""

# 检查目标 skills 目录下是否已存在同名 skill（任何层级）
skill_exists() {
    local name="$1"
    find "${HERMES_SKILLS_DIR}" -maxdepth 3 -type d -name "${name}" 2>/dev/null | grep -q .
}

for skill_dir in "${EMMA_SKILLS_DIR}"/skills/*/; do
    [ -d "${skill_dir}" ] || continue
    skill_name="$(basename "${skill_dir}")"

    if [ ! -f "${skill_dir}/SKILL.md" ]; then
        echo "  ⚠️  跳过 ${skill_name}（无 SKILL.md）"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if skill_exists "${skill_name}"; then
        existing_path="$(find "${HERMES_SKILLS_DIR}" -maxdepth 3 -type d -name "${skill_name}" 2>/dev/null | head -1)"
        echo "  📎  ${skill_name} — 已存在于 ${existing_path/#$HOME/\~}，跳过"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    cp -r "${skill_dir}" "${HERMES_SKILLS_DIR}/${skill_name}"
    echo "  ✅  ${skill_name} — 已安装"
    INSTALLED=$((INSTALLED + 1))
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 安装: ${INSTALLED}" 
echo "  ⏭️  跳过: ${SKIPPED}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 新会话自动生效"
