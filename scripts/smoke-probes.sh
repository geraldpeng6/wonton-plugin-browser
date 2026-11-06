# shellcheck shell=bash
# Browser：Bot 的可见 Chromium（noVNC 画面 + Playwright MCP）。sso=none、没有账号体系，身份项 N/A。
# 镜像没发布时在本机构建（README 的做法）。
export IDENTITY_NA=1
SMOKE_NOTE="noVNC 无账号体系（网关把关），身份项 N/A"

# 本机没有清单里那个摘要时按 README 构建，再把清单里的引用换成构建出来的（只改冒烟的副本）。
before_install() {
  local ref dig proxy="${https_proxy:-${HTTPS_PROXY:-}}" args=()
  ref="$(awk '/^ *image: /{print $2}' "$SMOKE_DIR/docker-compose.yml" | grep 'wonton-browser:' | head -1)"
  [[ -n "$ref" ]] || { echo "清单里没有 wonton-browser 镜像"; return 1; }
  if [[ -z "${SMOKE_BUILD:-}" ]] && docker image inspect "$ref" >/dev/null 2>&1; then
    echo "本机已有 $ref，不构建"
    return 0
  fi
  [[ -n "$proxy" ]] && args=(--build-arg "https_proxy=$proxy")
  (cd "$SMOKE_DIR" && nice -n 19 timeout 2400 docker buildx build --platform linux/amd64 --load \
    --network host "${args[@]}" -t ghcr.io/geraldpeng6/browser:dev images/browser) || return 1
  dig="$(docker image inspect ghcr.io/geraldpeng6/browser:dev --format '{{.Id}}')" || return 1
  sed -i -E "s#image: [^ ]*wonton-browser:[^ ]*#image: ghcr.io/geraldpeng6/browser:dev@$dig#" "$SMOKE_DIR/docker-compose.yml"
  grep -qF "ghcr.io/geraldpeng6/browser:dev@$dig" "$SMOKE_DIR/docker-compose.yml" || { echo "清单摘要没换成功"; return 1; }
}

web_assert() { grep -qiE 'novnc|vnc'; }   # 标准输入：noVNC 页面

mcp_check() { # 有只读工具（观察类）就真调一个，否则只断言 tools/list 有工具
  local n_mine tool out
  n_mine="$(jq --arg s "$SMOKE_SLUG" '[.[] | select(.name | startswith($s + "__"))] | length' "$SMOKE_TOOLS")"
  [[ "$n_mine" -ge 1 ]] || { echo "tools/list 没有 ${SMOKE_SLUG}__ 前缀工具"; return 1; }
  tool="$(jq -r --arg s "$SMOKE_SLUG" '[.[] | select(.name | startswith($s + "__") and .annotations.readOnlyHint == true)][0].name // ""' "$SMOKE_TOOLS")"
  if [[ -z "$tool" ]]; then
    SMOKE_NOTE="${SMOKE_NOTE}；工具没标 readOnlyHint，仅 tools/list，未调"
    return 0
  fi
  out="$(mcp call "$tool" '{}')" || { echo "只读工具 $tool 调用失败：$out"; return 1; }
  grep -qiE 'snapshot|console|page|tabs' <<<"$out" || { echo "只读工具 $tool 结果不像观察结果：$(head -c 150 <<<"$out")"; return 1; }
}
