// Pure handler: dependencies injected for deterministic tests; never logs tokens/keys.
const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS' };
export const providerEndpoint = 'https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/18/json';
export function createHandler({ key, authenticate, consumeQuota, contains, fetcher = fetch, clock = () => new Date() }) {
  const cache = new Map();
  const reply = (status, code, body = {}) => new Response(JSON.stringify({ code, ...body }), { status, headers });
  return async request => {
    if (request.method === 'OPTIONS') return new Response(null, {status:204, headers});
    if (request.method !== 'POST') return reply(405, 'METHOD');
    try {
      const user = await authenticate(request.headers.get('Authorization'));
      if (!user) return reply(401, 'AUTH_REQUIRED');
      if (!key) return reply(503, 'PROVIDER_NOT_CONFIGURED');
      if (Number(request.headers.get('content-length') ?? 0) > 1024) return reply(413, 'BODY_TOO_LARGE');
      const text = await request.text();
      if (text.length > 1024) return reply(413, 'BODY_TOO_LARGE');
      let body;
      try { body = JSON.parse(text); } catch { return reply(400, 'INVALID_JSON'); }
      const { latitude, longitude } = body ?? {};
      if (!Number.isFinite(latitude) || !Number.isFinite(longitude) ||
          Math.abs(latitude) > 90 || Math.abs(longitude) > 180) return reply(400, 'INVALID_POINT');
      if (!contains(latitude, longitude)) return reply(422, 'OUTSIDE_VERIFIED_COVERAGE');
      const point = `${latitude},${longitude}`, cached = cache.get(point), now = clock();
      if (cached && now.getTime() - Date.parse(cached.queriedAt) >= 0 &&
          now.getTime() - Date.parse(cached.queriedAt) < 60000) return reply(200, 'CACHED', cached);
      // Atomic database quota, shared across isolates. Fail closed if RPC missing.
      if (!await consumeQuota(user)) return reply(429, 'QUOTA_OR_CONFIGURATION');
      const url = new URL(providerEndpoint);
      url.search = new URLSearchParams({key, point, unit:'kmph'}).toString();
      const response = await fetcher(url, {signal:AbortSignal.timeout(4000)});
      if (!response.ok) return reply(response.status === 429 ? 429 : 502, 'PROVIDER_ERROR');
      const payload = await response.json();
      if (!payload.flowSegmentData) return reply(502, 'INVALID_PROVIDER_RESPONSE');
      const result = {provider:'TomTom', endpoint:providerEndpoint, queriedAt:clock().toISOString(),
        queryCoordinate:{latitude,longitude}, flowSegmentData:payload.flowSegmentData};
      if (cache.size >= 100) cache.delete(cache.keys().next().value);
      cache.set(point, result);
      return reply(200, 'OBSERVED', result);
    } catch {
      // Do not return provider error bodies/URLs: they can contain secrets.
      return reply(503, 'UNAVAILABLE');
    }
  };
}

export function insideGeometry(latitude, longitude, geometry) {
  const ringContains = ring => {
    let inside = false;
    for (let i=0,j=ring.length-1;i<ring.length;j=i++) {
      const [xi,yi]=ring[i], [xj,yj]=ring[j];
      if ((yi>latitude)!==(yj>latitude) && longitude<(xj-xi)*(latitude-yi)/(yj-yi)+xi) inside=!inside;
    }
    return inside;
  };
  const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] :
    geometry.type === 'MultiPolygon' ? geometry.coordinates : [];
  return polygons.some(rings => ringContains(rings[0]) && !rings.slice(1).some(ringContains));
}
