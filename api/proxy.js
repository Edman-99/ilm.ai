// Vercel serverless proxy to bypass CORS for Investlink API.
// Routes: /api/proxy/auth_db/login/ → https://app11-us-sw.ivlk.io/auth_db/login/

export default async function handler(req, res) {
  // CORS headers.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Extract path after /api/proxy/
  const targetPath = req.url.replace(/^\/api\/proxy\/?/, '/');
  const targetUrl = `https://app11-us-sw.ivlk.io${targetPath}`;

  try {
    const headers = { ...req.headers };
    // Remove host/origin headers that would confuse the target.
    delete headers.host;
    delete headers.origin;
    delete headers.referer;
    delete headers['x-forwarded-host'];
    delete headers['x-forwarded-proto'];
    delete headers['x-vercel-id'];
    delete headers['x-vercel-forwarded-for'];
    delete headers['x-real-ip'];
    delete headers.connection;

    const fetchOptions = {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        ...(headers.authorization ? { Authorization: headers.authorization } : {}),
      },
    };

    if (req.method !== 'GET' && req.method !== 'HEAD' && req.body) {
      fetchOptions.body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    }

    const response = await fetch(targetUrl, fetchOptions);
    const data = await response.text();

    res.status(response.status);
    // Forward content-type.
    const ct = response.headers.get('content-type');
    if (ct) res.setHeader('Content-Type', ct);

    return res.send(data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
}
