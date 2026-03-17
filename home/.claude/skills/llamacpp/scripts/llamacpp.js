const BASE = process.env.LLAMACPP_URL || 'http://127.0.0.1:58261';

function fetchWithTimeout(url, opts = {}, ms = 120000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), ms);
  return fetch(url, { ...opts, signal: ctrl.signal }).finally(() => clearTimeout(t));
}

async function request(method, endpoint, body = null, timeout = 120000) {
  const opts = { method };
  if (body) {
    opts.headers = { 'Content-Type': 'application/json' };
    opts.body = JSON.stringify(body);
  }
  const res = await fetchWithTimeout(`${BASE}${endpoint}`, opts, timeout);
  return res.json();
}

async function chatCompletions(body, timeout = 120000) {
  return request('POST', '/v1/chat/completions', body, timeout);
}

async function health(timeout = 5000) {
  const res = await fetchWithTimeout(`${BASE}/health`, {}, timeout);
  return res.ok ? (await res.json()).status === 'ok' : false;
}

module.exports = { BASE, request, chatCompletions, health, fetchWithTimeout };
