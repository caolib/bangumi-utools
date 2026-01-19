# uTools 插件开发模板

此仓库已被简化为一个通用的 uTools 插件模板。保留的通用功能：

- 深/浅/跟随系统主题支持（基于 Ant Design 主题切换）
- 配置持久化（使用 `window.utools.dbStorage`，见 `src/utils/store.js`）
- 导入/导出配置的预加载 API（`public/preload/services.js`）

快速开始：

1. 编辑 `public/plugin.json` 中的 `features`，添加你的功能点（code/cmds/explain）。
2. 在 `src/components/` 中实现你的页面和逻辑，`HomeView.vue` 为示例主页，`ConfigView.vue` 为示例配置页面。
3. 如需文件读写或导入导出，使用 `window.services` 中提供的方法。
4. 启动开发服务器：

```pwsh
pnpm dev
```

更多说明见项目内文件注释。



