# 云吞插件：Bot 的浏览器

开发流程见[插件开发指南](https://github.com/wontonapp/wonton-docs/blob/main/develop.md)。

Bot 在家里服务器上的一个带画面的 Chromium，Playwright MCP 驾驶它打开网页、点按、填表；用户在 App 里打开这个插件的网页
就能实时看到画面，随时接手，再交还给 Bot。

## 镜像与构建

浏览器镜像从固定摘要的 Debian 构建，包源固定到 snapshot；更新 snapshot 后要重测 CDP 与画面连接。
镜像由 Actions 工作流 `.github/workflows/publish-images.yml` 构建 amd64 和 arm64，推到 `ghcr.io/geraldpeng6/wonton-browser`。
改了镜像后把清单的 `version` 改成新版本并提交，手动运行工作流，再把运行摘要里的摘要写进 compose，然后 `scripts/check.sh --official`。

## 安全边界

CDP 和 MCP 的 nginx 入口拒绝网页来源，画面连接只接受核心注入的 `WONTON_APP_URL`；x11vnc 只用 Unix socket，
不开放可绕过 Origin 校验的原生 VNC/WebSocket TCP 端口。两个服务都非 root、根文件系统只读。
容器隔离是 Chromium `--no-sandbox` 的安全边界；不要把 CDP、MCP 或 VNC 端口发布到宿主。
镜像内各组件的完整许可证保留在 `/usr/share/doc/*/copyright`，清单列出主许可证及 noVNC 静态资源许可证。

## 先跑起来

```bash
scripts/dev.sh up
scripts/dev.sh install
```

`up` 在本机起一套云吞并打印它的地址，用 `scripts/dev.sh token` 输出的用户令牌登录；`install` 列出插件要的权限，确认后
装上并打印插件网页的地址，打开就是 Bot 的浏览器画面。

## 仓库里有什么

| 路径 | 内容 |
| --- | --- |
| `docker-compose.yml` | 插件本身：compose 加上 `x-wonton` 清单 |
| `icon.png`、`images/browser/` | 图标与浏览器镜像的构建配置 |
| `screenshots/` | 商店详情页里的截图 |
| `scripts/check.sh` | 检查插件包，规则和安装时一样 |
| `scripts/dev.sh` | 开发环境：起一套云吞，装、重装、卸载插件，看日志 |
| `scripts/publish.sh` | 发布一个版本：构建自己的镜像、按摘要写回、打 tag、推送 |
| `scripts/smoke-probes.sh` | `scripts/dev.sh smoke` 的网页与 MCP 工具探测 |
| `.github/workflows/publish-images.yml` | 构建并发布浏览器镜像的 Actions 工作流 |
| `AGENTS.md` | 给人和 AI 编程代理的规则 |
| `LICENSE`、`NOTICE` | 插件许可证、上游 BSD-3-Clause 许可证和商标声明 |

## 图标来源与授权

`icon.png` 是 Chromium 官方标志，未使用图片模型生成；来源、版权、处理方式、上游 BSD-3-Clause 全文和商标说明见
[NOTICE](NOTICE)。Chromium 名称与标志为其权利人的商标；本插件与 Chromium 项目及 Google 无官方合作或背书关系。
