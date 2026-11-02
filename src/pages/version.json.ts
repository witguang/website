import type { APIRoute } from 'astro';
import { execSync } from 'node:child_process';

/**
 * 构建指纹：每台机器上都能用 curl /version.json 查它跑的是哪一版。
 * 构建在 GitHub Actions 里做，提交号从 PUBLIC_BUILD_COMMIT 传进来；
 * 本地 `npm run build` 时退回读 git。
 */
function shortCommit(): string {
  const fromEnv = (import.meta.env as Record<string, string | undefined>).PUBLIC_BUILD_COMMIT;
  if (fromEnv) return fromEnv.slice(0, 7);

  try {
    return execSync('git rev-parse --short HEAD', {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return 'unknown';
  }
}

export const GET: APIRoute = () => {
  const body = {
    site: 'witguang',
    builtAt: new Date().toISOString(),
    commit: shortCommit(),
  };

  return new Response(`${JSON.stringify(body, null, 2)}\n`, {
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
};
