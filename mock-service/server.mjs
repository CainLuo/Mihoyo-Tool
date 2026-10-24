#!/usr/bin/env node
/**
 * 本机 Mock HTTP 服务（零第三方依赖）。
 *
 * 启动：
 *   node server.mjs
 *   node server.mjs --port 8787 --host 127.0.0.1 --delay 300
 *
 * App 侧默认访问 http://127.0.0.1:8787，真机/模拟器先执行：
 *   hdc rport tcp:8787 tcp:8787
 */

import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  MOCK_DELAY_MS,
  buildFixtureResponse,
  countFixtures,
  handleAccount,
  handleSign,
} from './router.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MAX_BODY_BYTES = 8 * 1024 * 1024;

function readArg(name, fallback) {
  const index = process.argv.indexOf(name);
  if (index >= 0 && index + 1 < process.argv.length) {
    return process.argv[index + 1];
  }
  return fallback;
}

const PORT = Number(readArg('--port', process.env.MOCK_PORT ?? '8787'));
const HOST = readArg('--host', '127.0.0.1');
const DELAY_MS = Number(readArg('--delay', String(MOCK_DELAY_MS)));
const FIXTURES_DIR = path.resolve(readArg('--fixtures', path.join(HERE, 'fixtures')));

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error(`request body exceeds ${MAX_BODY_BYTES} bytes`));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'content-type',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

function log(message) {
  console.log(`[mock] ${new Date().toISOString()} ${message}`);
}

async function handleRpc(body) {
  const payload = JSON.parse(body);
  if (payload === null || typeof payload !== 'object') {
    throw new Error('request body must be a JSON object');
  }

  const startedAt = Date.now();
  if (DELAY_MS > 0) {
    await sleep(DELAY_MS);
  }

  const kind = String(payload.kind ?? '');
  if (kind === 'fixture') {
    const result = buildFixtureResponse(FIXTURES_DIR, payload);
    if (result.file !== null) {
      log(`fixture ${payload.path} -> ${result.file} (${Date.now() - startedAt}ms)`);
    } else {
      log(`fixture ${payload.path} -> empty (${Date.now() - startedAt}ms) candidates=${result.resolved.candidates.join(', ')}`);
    }
    return result.response;
  }
  if (kind === 'account') {
    const response = handleAccount(payload);
    log(`account ${payload.method} -> retcode=${response.retcode} (${Date.now() - startedAt}ms)`);
    return response;
  }
  if (kind === 'sign') {
    const response = handleSign(FIXTURES_DIR, payload);
    log(`sign ${payload.method} -> retcode=${response.retcode} (${Date.now() - startedAt}ms)`);
    return response;
  }
  throw new Error(`unknown rpc kind: ${kind}`);
}

const server = http.createServer(async (req, res) => {
  const requestUrl = new URL(req.url ?? '/', `http://${req.headers.host ?? `${HOST}:${PORT}`}`);
  const pathname = requestUrl.pathname;

  if (req.method === 'OPTIONS') {
    sendJson(res, 204, {});
    return;
  }

  if (req.method === 'GET' && pathname === '/__health') {
    sendJson(res, 200, {
      ok: true,
      fixtures: countFixtures(FIXTURES_DIR),
      delayMs: DELAY_MS,
      fixturesDir: FIXTURES_DIR,
    });
    return;
  }

  if (req.method === 'GET' && pathname === '/') {
    sendJson(res, 200, {
      name: 'mihoyo-tool-mock-service',
      rpc: 'POST /__mock/rpc',
      health: 'GET /__health',
      delayMs: DELAY_MS,
    });
    return;
  }

  if (req.method === 'POST' && pathname === '/__mock/rpc') {
    try {
      const body = await readBody(req);
      const response = await handleRpc(body);
      sendJson(res, 200, response);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      log(`rpc error: ${message}`);
      sendJson(res, 400, { error: message });
    }
    return;
  }

  sendJson(res, 404, { error: `not found: ${req.method} ${pathname}` });
});

server.on('error', (error) => {
  console.error(`[mock] server error: ${error.message}`);
  process.exitCode = 1;
});

server.listen(PORT, HOST, () => {
  const fixtures = countFixtures(FIXTURES_DIR);
  log(`listening on http://${HOST}:${PORT}`);
  log(`fixtures: ${fixtures} (${FIXTURES_DIR})`);
  log(`delay: ${DELAY_MS}ms`);
  if (HOST === '127.0.0.1' || HOST === 'localhost') {
    log('真机/模拟器请先执行: hdc rport tcp:8787 tcp:8787');
  }
});

function shutdown(signal) {
  log(`${signal} received, shutting down`);
  server.close(() => process.exit(0));
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
