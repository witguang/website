# ascii-sharks（内置副本）

来源：[stackedlol/ascii-sharks](https://github.com/stackedlol/ascii-sharks)，提交 `a0074c1`，MIT 协议（见同目录 `LICENSE`）。

这里是从原仓库 `src/` 原样拷过来的运行时（去掉了 React 包装 `react.tsx`），没有改逻辑，只是换了目录。它的用途是给站点提供一个可嵌入的 ASCII 海洋：canvas 上跑鱼群和鲨鱼，鱼群会因为鼠标靠近而散开，点击水面会有波纹。

```ts
import { OceanEngine } from './src/ascii-sharks';

const engine = new OceanEngine(canvas, [{ kind: 'hammerhead', size: 1 }]);
// 不需要时 engine.destroy()
```

## 本站改动

上游代码除了换目录以外只有一处改动，都集中在 `engine.ts`，方便以后对比升级：

| 改动 | 原因 |
| --- | --- |
| 新增 `OceanOptions { play?: boolean }` 构造函数第三参 | 页面需要「默认播放」，而上游遇到 `prefers-reduced-motion: reduce` 会永久停在静帧 |
| 新增 `frozen` getter | 把「用户暂停」和「系统要求减少动效」合并成一个判断，替换掉原来散落的 `reducedMotion.matches` |
| 新增 `setPlaying(playing)` | 页面上那个「暂停 / 播放」小开关；播放时把 `ignoreReducedMotion` 置为 true |

替换点共 5 处，都是原来的 `this.reducedMotion.matches` → `this.frozen`。其余逻辑（鱼群、渲染、指针、IO 暂停）未动。

## 注意事项


- 引擎按**深色背景**设计（黑底、冷白字形、暗色鲨鱼剪影），所以嵌入时给它一块黑色画布，不要指望它适配浅色背景。
- 字形来自 canvas 的 `font-family`，所以画布上要有等宽字体。
- 引擎自己处理了 `ResizeObserver`、`IntersectionObserver`（滚出视口就暂停）、`prefers-reduced-motion`（只画一帧静帧）、指针交互。

升级方式：重新从上游拷 `engine.ts / index.ts / math.ts / renderer.ts / species.ts / world.ts` 覆盖即可。
