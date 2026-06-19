#!/bin/bash
# ==============================================================================
# 📦 emma-skills 一键安装脚本
# 用法: bash install.sh
# 将仓库中所有自定义技能部署到 ~/.hermes/skills/
# ==============================================================================
set -euo pipefail

EMMA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_SKILLS="${HOME}/.hermes/skills"
INSTALLED=0
SKIPPED=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e " ${GREEN}✅${NC} $1"; }
warn() { echo -e " ${YELLOW}⚠️${NC}  $1"; }

echo -e "\n${CYAN}━━━ Emma Skills 安装器 ━━━${NC}\n"
echo "   来源: ${EMMA_DIR}/skills"
echo "   目标: ${HERMES_SKILLS}/"
echo ""

# 检查 Hermes 是否已安装
if [ ! -d "${HERMES_SKILLS}" ]; then
  echo -e " ${RED}❌${NC} 未找到 ~/.hermes/skills/，请先安装 Hermes Agent"
  echo "   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
  exit 1
fi

# 检测技能是否已存在（任意层级）
skill_exists() {
  local name="$1"
  find "${HERMES_SKILLS}" -maxdepth 4 -type d -name "${name}" 2>/dev/null | grep -q . && echo "found" || echo ""
}

install_skill_dir() {
  local src="$1"
  local skill_name="$(basename "$src")"
  
  if [ ! -f "${src}/SKILL.md" ]; then
    echo -e "  ${YELLOW}⚠️${NC}  跳过 ${skill_name}（无 SKILL.md）"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  
  local existing="$(skill_exists "${skill_name}")"
  if [ -n "$existing" ]; then
    local existing_path="$(find "${HERMES_SKILLS}" -maxdepth 4 -type d -name "${skill_name}" 2>/dev/null | head -1)"
    echo -e "  ${CYAN}📎${NC}  ${skill_name} — 已存在（${existing_path/#$HOME/\~}），跳过"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  
  # 确定目标路径：保留仓库中的相对路径结构
  local rel="${src#${EMMA_DIR}/skills/}"
  local dest="${HERMES_SKILLS}/${rel}"
  
  mkdir -p "$(dirname "$dest")"
  cp -r "$src" "$dest"
  echo -e "  ${GREEN}✅${NC}  ${skill_name} — 已安装"
  INSTALLED=$((INSTALLED + 1))
}

# 安装分类目录下的技能
for skill_dir in "${EMMA_DIR}"/skills/*/*/; do
  [ -d "$skill_dir" ] || continue
  install_skill_dir "$skill_dir"
done

# 安装根目录下的 uncategorized 技能
for skill_dir in "${EMMA_DIR}"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  # 跳过子目录（已被上面的循环处理过）
  [ -d "${skill_dir%}/../${skill_dir#*/}" ] && continue
  install_skill_dir "$skill_dir"
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}✅ 安装: ${INSTALLED}${NC}"
echo -e "  ${YELLOW}⏭️  跳过: ${SKIPPED}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e " ${CYAN}💡${NC} 新会话自动生效，或运行:"
echo "   hermes skills list"
echo ""
