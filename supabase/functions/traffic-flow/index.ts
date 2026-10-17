import { createHandler, insideGeometry } from './handler.mjs';
import { geometries } from './geometries.generated.ts';
const base = Deno.env.get('SUPABASE_URL')!;
const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
Deno.serve(createHandler({
  key: Deno.env.get('TOMTOM_API_KEY'),
  contains: (lat: number, lon: number) => geometries.some(g => insideGeometry(lat, lon, g)),
  authenticate: async (authorization: string | null) => {
    if (!authorization?.startsWith('Bearer ')) return null;
    const result = await fetch(`${base}/auth/v1/user`, {
      headers: {apikey:anon, Authorization:authorization}, signal:AbortSignal.timeout(4000),
    });
    if (!result.ok) return null;
    return (await result.json()).id ?? null;
  },
  consumeQuota: async (user: string) => {
    const result = await fetch(`${base}/rest/v1/rpc/consume_traffic_quota`, {
      method:'POST', headers:{apikey:service, Authorization:`Bearer ${service}`, 'Content-Type':'application/json'},
      body:JSON.stringify({caller:user}), signal:AbortSignal.timeout(4000),
    });
    return result.ok && await result.json() === true;
  },
}));
