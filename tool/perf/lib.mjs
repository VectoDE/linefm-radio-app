// Shared helpers for tool/perf (Node standard library only).
import { execFileSync } from 'node:child_process';
import os from 'node:os';

/** Median, minimum, maximum, count and coefficient of variation (in %). */
export function stats(values) {
  const v = values.filter((x) => typeof x === 'number' && Number.isFinite(x)).sort((a, b) => a - b);
  if (v.length === 0) return { n: 0, median: null, min: null, max: null, cv: null };
  const mid = Math.floor(v.length / 2);
  const median = v.length % 2 ? v[mid] : (v[mid - 1] + v[mid]) / 2;
  const mean = v.reduce((a, b) => a + b, 0) / v.length;
  const sd = Math.sqrt(v.reduce((a, b) => a + (b - mean) ** 2, 0) / v.length);
  return {
    n: v.length,
    median,
    min: v[0],
    max: v[v.length - 1],
    cv: mean === 0 ? 0 : (sd / mean) * 100,
  };
}

export function commitSha() {
  if (process.env.GITHUB_SHA) return process.env.GITHUB_SHA;
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  } catch {
    return 'unknown';
  }
}

/** Environment for the report: runner, CPU, commit, run URL. */
export function environment() {
  const cpus = os.cpus();
  const server = process.env.GITHUB_SERVER_URL;
  const repo = process.env.GITHUB_REPOSITORY;
  const run = process.env.GITHUB_RUN_ID;
  return {
    commit: commitSha(),
    ref: process.env.GITHUB_REF_NAME ?? null,
    runUrl: server && repo && run ? `${server}/${repo}/actions/runs/${run}` : null,
    runner: {
      name: process.env.RUNNER_NAME ?? os.hostname(),
      os: process.env.RUNNER_OS ?? os.platform(),
      image: process.env.ImageOS ?? null,
      imageVersion: process.env.ImageVersion ?? null,
      arch: process.env.RUNNER_ARCH ?? os.arch(),
    },
    cpu: { model: cpus[0]?.model ?? 'unknown', cores: cpus.length },
    memGiB: Math.round((os.totalmem() / 2 ** 30) * 10) / 10,
    node: process.version,
    at: new Date().toISOString(),
  };
}
