// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ZENOVA GITHUB API v20 FINAL
// 3-tier state fetching + circuit breaker + smart dispatch
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
import { Octokit } from '@octokit/rest';
import { logger } from './logger.js';

// â•â•â• AUTO-INJECTED: Duration validator â•â•â•
function normalizeDuration(input) {
  if (!input) return '5h00m';
  const str = String(input).toLowerCase().trim();
  const hourMatch = str.match(/(\d+)\s*h/);
  const hours = hourMatch ? parseInt(hourMatch[1]) : 5;
  if (hours <= 1) return '1h';
  if (hours <= 3) return '3h';
  return '5h00m';
}

// â•â•â• AUTO-INJECTED: Remove invalid workflow inputs â•â•â•
const VALID_WORKFLOW_INPUTS = [
  'machine_id',
  'owner_discord_id',
  'duration',
  'windows_image',
  'drive_letter',
  'vhd_size_gb',
  'fixed_password',
  'choco_packages'
];

function sanitizeInputs(obj) {
  const result = {};
  for (const key of VALID_WORKFLOW_INPUTS) {
    if (obj[key] !== undefined && obj[key] !== null && obj[key] !== '') {
      result[key] = obj[key];
    }
  }
  // LuÃ´n Ä‘áº£m báº£o duration há»£p lá»‡
  if (result.duration) {
    result.duration = normalizeDuration(result.duration);
  } else {
    result.duration = '5h00m';
  }
  return result;
}

const cfg = {
  owner: process.env.GH_OWNER,
  repo: process.env.GH_REPO,
  branch: process.env.GH_BRANCH || 'main',
  workflow: process.env.GH_WORKFLOW || 'aistv-rdp.yml'
};

export const octokit = new Octokit({
  auth: process.env.GH_TOKEN,
  userAgent: 'zenova-bot/20.0'
});

const tag = (id) => `zenova-storage-${id}`;
const branch = (id) => `zenova-state-${id}`;

async function ghApi(path, options = {}) {
  const url = 'https://api.github.com' + path;
  const headers = {
    'Accept': 'application/vnd.github+json',
    'Authorization': 'Bearer ' + process.env.GH_TOKEN,
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'zenova-bot/20.0',
    ...(options.headers || {})
  };
  const res = await fetch(url, { ...options, headers, cache: 'no-store' });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error('HTTP ' + res.status + ': ' + txt.slice(0, 200));
  }
  if (res.status === 204) return null;
  return await res.json();
}

export async function dispatchCreate(inputs) {
  if (!/^[a-z0-9\-]+$/.test(inputs.machine_id)) throw new Error('Machine ID: a-z, 0-9, dash');
  const c = { machine_id: inputs.machine_id };
  if (inputs.owner_discord_id) c.owner_discord_id = String(inputs.owner_discord_id);
  c.restore_data = (inputs.restore_data === true || inputs.restore_data === 'true') ? 'true' : 'false';
  const d = String(inputs.duration || '5h00m').toLowerCase();
  const h = d.match(/(\d+)\s*h/);
  const hrs = h ? parseInt(h[1]) : 5;
  c.duration = hrs <= 1 ? '1h' : hrs <= 3 ? '3h' : '5h00m';
  c.windows_image = String(inputs.windows_image || 'windows-2025').toLowerCase().includes('2022') ? 'windows-2022' : 'windows-2025';
  c.vhd_size_gb = String(inputs.vhd_size_gb || '1024');
  c.fixed_password = inputs.fixed_password || process.env.RDP_PASSWORD || 'ABC123@';
  c.choco_packages = String(inputs.choco_packages || '');
  logger.cmd('Dispatch via repository_dispatch: ' + c.machine_id);
  await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/dispatches', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ event_type: 'zenova-create', client_payload: c })
  });
  logger.ok('Dispatched: ' + c.machine_id);
}

export async function listMachines() {
  const releases = await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/releases?per_page=100');
  return releases
    .filter(r => r.tag_name.startsWith('zenova-storage-'))
    .map(r => ({
      id: r.tag_name.replace('zenova-storage-', ''),
      tag: r.tag_name,
      releaseId: r.id,
      assets: r.assets.map(a => ({ name: a.name, size: a.size, id: a.id })),
      created: r.created_at,
      updated: r.updated_at,
      url: r.html_url
    }));
}

async function fetchViaApiAsset(stateAssetId) {
  try {
    const res = await fetch(
      'https://api.github.com/repos/' + cfg.owner + '/' + cfg.repo + '/releases/assets/' + stateAssetId,
      {
        headers: {
          'Authorization': 'Bearer ' + process.env.GH_TOKEN,
          'Accept': 'application/octet-stream',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'zenova-bot/20.0',
          'Cache-Control': 'no-cache, no-store',
          'If-None-Match': '""'
        },
        redirect: 'follow',
        cache: 'no-store'
      }
    );
    if (!res.ok) return null;
    const data = await res.json();
    data._fetchedAt = Date.now();
    data._source = 'api_asset';
    return data;
  } catch (e) {
    logger.dbg('api_asset: ' + e.message);
    return null;
  }
}

async function fetchViaDownloadUrl(downloadUrl) {
  try {
    const ts = Date.now();
    const rnd = Math.random().toString(36).slice(2, 8);
    const url = downloadUrl + '?download=1&t=' + ts + '&r=' + rnd;
    
    const res = await fetch(url, {
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
        'Pragma': 'no-cache',
        'User-Agent': 'zenova-bot/20.0'
      },
      redirect: 'follow',
      cache: 'no-store'
    });
    if (!res.ok) return null;
    const data = await res.json();
    data._fetchedAt = Date.now();
    data._source = 'download_url';
    return data;
  } catch (e) {
    logger.dbg('download_url: ' + e.message);
    return null;
  }
}

async function fetchViaRunLog(machineId) {
  try {
    const runs = await listRecentRuns(15);
    if (!runs.length) return null;

    let targetRun = runs.find(r => 
      (r.display_title || '').toLowerCase().includes(machineId.toLowerCase())
    ) || runs[0];

    logger.dbg('run_log: check #' + targetRun.number + ' (' + targetRun.status + ')');
    
    const log = await getRunLogTail(targetRun.id, 3000);
    if (!log || log === '(no log)' || log.length < 100) {
      return null;
    }

    const ipPatterns = [
      /IP\s*:\s*(100\.\d+\.\d+\.\d+)/i,
      /Tailscale IP\s*[:=]\s*(100\.\d+\.\d+\.\d+)/i,
      /TAILSCALE_IP\s*[:=]\s*(100\.\d+\.\d+\.\d+)/i,
      /(?:IP|ip)\s*(?:lÃ |is|=|:)\s*(100\.\d+\.\d+\.\d+)/i,
      /\b(100\.\d{1,3}\.\d{1,3}\.\d{1,3})\b/
    ];
    
    let ip = null;
    for (const pattern of ipPatterns) {
      const m = log.match(pattern);
      if (m) { ip = m[1]; break; }
    }
    
    if (!ip) {
      logger.dbg('run_log: no IP found');
      return null;
    }

    const userMatch = log.match(/(?:RDP_USER|User|user|TÃ i khoáº£n)\s*[:=]\s*([a-zA-Z][\w\-]{2,})/i);
    const user = userMatch ? userMatch[1] : 'runneradmin';

    const passMatch = log.match(/(?:Pass|Password|Máº­t kháº©u)\s*[:=]\s*([^\s]+)/i);
    let password = process.env.RDP_PASSWORD || 'ABC123@'; if (passMatch && !passMatch[1].includes('secret') && !passMatch[1].includes('dÃ¹ng')) { password = passMatch[1]; }

    const hostMatch = log.match(/(?:Hostname|Host|hostname)\s*[:=]\s*([a-zA-Z0-9\-\.]{5,})/i);
    const tailscaleHostname = hostMatch ? hostMatch[1] : '';

    const isReady = /READY|Sáº´N SÃ€NG|ready to connect|3389.*listen|RDP.*3389/i.test(log);

    logger.ok('LOG FALLBACK: ' + machineId + ' | ' + ip + ' | ' + user + ' | #' + targetRun.number);

    return {
      machineId,
      ownerDiscordId: null,
      user,
      password,
      tailscaleIp: ip,
      tailscaleHostname,
      osBuild: '26100',
      windowsImage: 'windows-2025',
      status: isReady ? 'ready' : 'starting',
      step: isReady ? 'ready' : 'init',
      ready: isReady,
      partialReady: true,
      _fromLog: true,
      _runId: targetRun.id,
      _runNumber: targetRun.number,
      _fetchedAt: Date.now(),
      _source: 'run_log'
    };
  } catch (e) {
    logger.dbg('run_log: ' + e.message);
    return null;
  }
}

export async function getStateJson(machineId) {
  try {
    let rel;
    try {
      rel = await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/releases/tags/' + tag(machineId));
    } catch (e) {
      if (e.message.includes('404')) {
        logger.dbg('getStateJson: release not found, fallback log');
        return await fetchViaRunLog(machineId);
      }
      throw e;
    }

    const stateAsset = (rel.assets || []).find(a => a.name === 'state.json');
    
    if (!stateAsset) {
      logger.dbg('getStateJson: no state.json, fallback log');
      return await fetchViaRunLog(machineId);
    }

    logger.dbg('getStateJson: state.json id=' + stateAsset.id + ' updated=' + stateAsset.updated_at);

    let state = await fetchViaApiAsset(stateAsset.id);
    if (state && state.tailscaleIp && state.tailscaleIp !== '?' 
        && state.user && state.user !== '?') {
      return state;
    }

    if (stateAsset.browser_download_url) {
      state = await fetchViaDownloadUrl(stateAsset.browser_download_url);
      if (state && state.tailscaleIp && state.tailscaleIp !== '?' 
          && state.user && state.user !== '?') {
        return state;
      }
    }

    const logState = await fetchViaRunLog(machineId);
    if (logState) {
      if (state?.ownerDiscordId) logState.ownerDiscordId = state.ownerDiscordId;
      if (state?.password && state.password !== '?') logState.password = state.password;
      return logState;
    }

    return state;
  } catch (e) {
    logger.dbg('getStateJson: ' + e.message);
    return await fetchViaRunLog(machineId);
  }
}

export async function getManifest(machineId) {
  return getStateJson(machineId);
}

export async function getUserMachine(discordUserId) {
  const machines = await listMachines();
  for (const m of machines.slice(0, 30)) {
    const state = await getStateJson(m.id);
    if (!state) continue;
    if (state.ownerDiscordId === discordUserId) {
      return { ...m, manifest: state };
    }
  }
  return null;
}

export async function isMachineOwner(discordUserId, machineId) {
  const state = await getStateJson(machineId);
  if (!state) return false;
  if (!state.ownerDiscordId) return true;
  return state.ownerDiscordId === discordUserId;
}

export async function listActiveRuns() {
  const data = await ghApi(
    '/repos/' + cfg.owner + '/' + cfg.repo + '/actions/workflows/' + cfg.workflow + '/runs?per_page=50'
  );
  return (data.workflow_runs || [])
    .filter(r => ['in_progress', 'queued', 'waiting', 'requested'].includes(r.status))
    .map(r => ({
      id: r.id,
      number: r.run_number,
      status: r.status,
      started: r.run_started_at || r.created_at,
      url: r.html_url,
      display_title: r.display_title || ''
    }));
}

export async function listRecentRuns(limit = 20) {
  const data = await ghApi(
    '/repos/' + cfg.owner + '/' + cfg.repo + '/actions/workflows/' + cfg.workflow + '/runs?per_page=' + limit
  );
  return (data.workflow_runs || []).map(r => ({
    id: r.id,
    number: r.run_number,
    status: r.status,
    conclusion: r.conclusion,
    started: r.run_started_at || r.created_at,
    updated: r.updated_at,
    url: r.html_url,
    event: r.event,
    display_title: r.display_title || ''
  }));
}

export async function waitForWorkflowCompletion(
  machineId, 
  maxWaitMs = 1800000,
  intervalMs = 2000,
  onProgress = null
) {
  const startTime = Date.now();
  logger.info('Poll (3-tier + appsReady) ' + machineId + ' | max ' + Math.round(maxWaitMs/1000) + 's');

  await new Promise(r => setTimeout(r, 3000));

  let attempt = 0;
  let consecutiveFails = 0;
  let bestState = null;
  let lastLogAt = 0;
  let phase = 'init';

  while (Date.now() - startTime < maxWaitMs) {
    attempt++;
    try {
      const state = await getStateJson(machineId);
      
      if (state && state.tailscaleIp && state.tailscaleIp !== '?') {
        bestState = state;
        consecutiveFails = 0;
        phase = state.status || 'init';
      } else {
        consecutiveFails++;
      }
      
      if (consecutiveFails >= 30) {
        logger.warn('Circuit breaker: 30 fails');
        break;
      }

      if (onProgress) {
        try { await onProgress({ attempt, state, elapsed: Date.now() - startTime }); } catch {}
      }

      // SUCCESS: cÃ³ IP + user + appsReady
      const hasIp = state && state.tailscaleIp && state.tailscaleIp !== '?';
      const hasUser = state && state.user && state.user !== '?';
      const appsReady = state && (state.appsReady === true || state.status === 'ready');
      
      if (hasIp && hasUser && appsReady) {
        logger.ok('READY attempt=' + attempt + ' t=' + Math.round((Date.now() - startTime) / 1000) + 's src=' + (state._source || '?'));
        return { 
          success: true, 
          manifest: state, 
          attempts: attempt, 
          elapsed: Date.now() - startTime, 
          fromLog: state._fromLog || false 
        };
      }

      // Log má»—i 15 láº§n
      if (attempt - lastLogAt >= 15) {
        logger.info('Poll ' + attempt + ' | step:' + (state?.step || '-') + ' | apps:' + (appsReady ? 'YES' : 'NO') + ' | ' + Math.round((Date.now() - startTime) / 1000) + 's');
        lastLogAt = attempt;
      }

      // Progressive: 2s â†’ 3s â†’ 5s
      let waitTime = intervalMs;
      if (attempt > 60) waitTime = intervalMs * 2;
      if (attempt > 150) waitTime = intervalMs * 3;
      
      await new Promise(r => setTimeout(r, waitTime));
      
    } catch (e) {
      logger.dbg('Poll fail: ' + e.message);
      consecutiveFails++;
      await new Promise(r => setTimeout(r, 3000));
    }
  }

  if (bestState) {
    logger.warn('Timeout but cÃ³ partial state');
    return { success: true, manifest: bestState, attempts: attempt, elapsed: Date.now() - startTime, fallback: true };
  }

  return { success: false, error: 'Timeout ' + Math.round(maxWaitMs/1000) + 's', attempts: attempt };
}

export async function transferOwnership(machineId, newOwnerId, requesterId, isAdmin = false) {
  const state = await getStateJson(machineId);
  if (!state) throw new Error('Machine not found: ' + machineId);

  if (!isAdmin && state.ownerDiscordId && state.ownerDiscordId !== requesterId) {
    throw new Error('Báº¡n khÃ´ng pháº£i chá»§ mÃ¡y');
  }

  if (state.ownerDiscordId === newOwnerId) {
    throw new Error('MÃ¡y Ä‘Ã£ thuá»™c user nÃ y');
  }

  const newState = {
    ...state,
    ownerDiscordId: newOwnerId,
    previousOwnerId: state.ownerDiscordId || null,
    transferredUtc: new Date().toISOString(),
    transferredBy: requesterId
  };

  delete newState._fetchedAt;
  delete newState._source;
  delete newState._fromLog;
  delete newState._runId;
  delete newState._runNumber;

  const rel = await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/releases/tags/' + tag(machineId));
  const stateAsset = rel.assets.find(a => a.name === 'state.json');
  if (!stateAsset) throw new Error('state.json missing');

  await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/releases/assets/' + stateAsset.id, { method: 'DELETE' });

  const uploadUrl = rel.upload_url.replace(/\{.*\}/, '') + '?name=state.json';
  const jsonStr = JSON.stringify(newState, null, 2);
  const res = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + process.env.GH_TOKEN,
      'Content-Type': 'application/json',
      'X-GitHub-Api-Version': '2022-11-28'
    },
    body: jsonStr
  });

  if (!res.ok) {
    throw new Error('Upload fail: HTTP ' + res.status);
  }

  logger.ok(`Transferred ${machineId}: ${state.ownerDiscordId} -> ${newOwnerId}`);
  return { success: true, machineId, previousOwner: state.ownerDiscordId, newOwner: newOwnerId };
}

export async function deleteMachine(machineId, requesterId, isAdmin = false) {
  if (!isAdmin) {
    const owned = await isMachineOwner(requesterId, machineId);
    if (!owned) throw new Error('KhÃ´ng pháº£i mÃ¡y cá»§a báº¡n');
  }
  
  try {
    const runs = await listRecentRuns(20);
    const active = runs.filter(r => ['in_progress', 'queued'].includes(r.status));
    for (const r of active) {
      try { await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/actions/runs/' + r.id + '/cancel', { method: 'POST' }); } catch {}
    }
    await new Promise(r => setTimeout(r, 3000));
  } catch {}
  
  try {
    const rel = await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/releases/tags/' + tag(machineId));
    await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/releases/' + rel.id, { method: 'DELETE' });
  } catch {}
  
  try {
    await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/git/refs/heads/' + branch(machineId), { method: 'DELETE' });
  } catch {}
  
  logger.ok('Deleted: ' + machineId);
}

export async function cancelRun(runId) {
  await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/actions/runs/' + runId + '/cancel', { method: 'POST' });
}

export async function getRunLogTail(runId, lines = 80) {
  try {
    const jobs = await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/actions/runs/' + runId + '/jobs');
    const logs = [];
    
    for (const job of jobs.jobs || []) {
      try {
        const res = await fetch(
          'https://api.github.com/repos/' + cfg.owner + '/' + cfg.repo + '/actions/jobs/' + job.id + '/logs',
          {
            headers: {
              Authorization: 'Bearer ' + process.env.GH_TOKEN,
              Accept: 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28'
            },
            redirect: 'follow'
          }
        );
        if (res.ok) {
          const txt = await res.text();
          logs.push(txt);
        }
      } catch {}
    }
    
    const fullLog = logs.join('\n');
    return fullLog.split('\n').slice(-lines).join('\n');
  } catch (e) {
    return 'Error: ' + e.message;
  }
}

export async function cleanupOrphanReleases() {
  const machines = await listMachines();
  const orphans = [];
  
  for (const m of machines) {
    const hasState = m.assets.some(a => a.name === 'state.json');
    const hasDrive = m.assets.some(a => a.name.startsWith('zenova-drive.'));
    
    if (!hasState && !hasDrive) {
      orphans.push(m);
    }
  }
  
  logger.info('Found ' + orphans.length + ' orphan releases');
  
  for (const o of orphans) {
    try {
      const age = (Date.now() - new Date(o.created).getTime()) / 1000 / 3600;
      if (age > 1) {
        await ghApi('/repos/' + cfg.owner + '/' + cfg.repo + '/releases/' + o.releaseId, { method: 'DELETE' });
        logger.ok('Cleaned: ' + o.id);
      }
    } catch (e) {
      logger.dbg('Clean fail ' + o.id + ': ' + e.message);
    }
  }
  
  return orphans.length;
}