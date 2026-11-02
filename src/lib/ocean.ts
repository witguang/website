import { OceanEngine } from '../ascii-sharks/index';
import type { SharkSpec } from '../ascii-sharks/index';

const STORAGE_KEY = 'ocean-motion';

type Pref = 'play' | 'pause';

interface OceanInstance {
  engine: OceanEngine;
  button: HTMLButtonElement | null;
  playing: boolean;
}

const instances: OceanInstance[] = [];
let wired = false;

/**
 * 把页面上所有 canvas[data-ocean] 挂上引擎。
 * 容器（[data-ocean-scope]）里如果有 [data-ocean-toggle]，就把它接成播放 / 暂停开关。
 * 默认就是游动的（不理会 prefers-reduced-motion）；用户点过暂停才记成暂停。
 * 可以安全地重复调用：每块画布只会挂一次，pagehide 时统一销毁。
 */
export function mountOceans(root: ParentNode = document): void {
  root.querySelectorAll<HTMLCanvasElement>('canvas[data-ocean]').forEach(mountOne);
  if (wired) return;
  wired = true;
  window.addEventListener('pagehide', teardown, { once: true });
}

function mountOne(canvas: HTMLCanvasElement): void {
  if (canvas.dataset.oceanMounted === '1') return;
  canvas.dataset.oceanMounted = '1';

  let sharks: SharkSpec[] | undefined;
  try {
    sharks = JSON.parse(canvas.dataset.sharks ?? 'null') ?? undefined;
  } catch {
    sharks = undefined;
  }

  const stored = readPref();
  // 默认游动；只有用户明确点过暂停才停
  const playing = stored !== 'pause';

  let engine: OceanEngine;
  try {
    engine = new OceanEngine(canvas, sharks, { play: playing });
  } catch (error) {
    // 拿不到 2D context（隐私模式、被策略禁用等）时就留一块黑场，不要炸掉整页
    canvas.dataset.oceanFailed = 'true';
    console.warn('[ascii-sharks] 初始化失败', error);
    return;
  }

  const scope = canvas.closest('[data-ocean-scope]');
  const button = scope?.querySelector<HTMLButtonElement>('[data-ocean-toggle]') ?? null;

  const instance: OceanInstance = { engine, button, playing };
  instances.push(instance);
  apply(instance);

  // 开发时方便在控制台里查状态：canvas.__oceanEngine
  if (import.meta.env.DEV) (canvas as unknown as Record<string, unknown>).__oceanEngine = engine;

  button?.addEventListener('click', () => {
    instance.playing = !instance.playing;
    writePref(instance.playing ? 'play' : 'pause');
    apply(instance);
  });
}

function apply(instance: OceanInstance): void {
  instance.engine.setPlaying(instance.playing);

  const { button } = instance;
  if (!button) return;

  button.setAttribute('aria-pressed', String(instance.playing));
  const glyph = button.querySelector('[data-ocean-glyph]');
  const label = button.querySelector('[data-ocean-label]');
  if (glyph) glyph.textContent = instance.playing ? '❚❚' : '▶';
  if (label) label.textContent = instance.playing ? '暂停' : '播放';
  button.title = instance.playing ? '暂停这片海' : '继续播放';
}

function readPref(): Pref | null {
  try {
    const value = localStorage.getItem(STORAGE_KEY);
    return value === 'play' || value === 'pause' ? value : null;
  } catch {
    return null;
  }
}

function writePref(value: Pref): void {
  try {
    localStorage.setItem(STORAGE_KEY, value);
  } catch {
    // 隐私模式下写不了，忽略
  }
}

function teardown(): void {
  instances.forEach((instance) => instance.engine.destroy());
  instances.length = 0;
  wired = false;
}
