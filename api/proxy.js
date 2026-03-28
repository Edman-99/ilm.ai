export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();

  // Get target path from query param or URL.
  let targetPath = req.query.path || '';
  if (!targetPath) {
    targetPath = req.url.replace(/^\/api\/proxy\/?/, '');
    targetPath = targetPath.split('?')[0];
  }
  if (!targetPath.startsWith('/')) targetPath = '/' + targetPath;

  // Forward query params (except 'path').
  const url = new URL(`https://app12-us-sw.ivlk.io${targetPath}`);
  for (const [k, v] of Object.entries(req.query)) {
    if (k !== 'path') url.searchParams.set(k, v);
  }

  try {
    const fetchOpts = {
      method: req.method,
      headers: { 'Content-Type': 'application/json' },
    };

    if (req.headers.authorization) {
      fetchOpts.headers['Authorization'] = req.headers.authorization;
    }

    if (req.method !== 'GET' && req.method !== 'HEAD' && req.body) {
      fetchOpts.body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    }

    const response = await fetch(url.toString(), fetchOpts);
    const data = await response.text();

    const ct = response.headers.get('content-type');
    if (ct) res.setHeader('Content-Type', ct);

    return res.status(response.status).send(data);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
