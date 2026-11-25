// Email links always land on an HTTPS page before a user chooses to open the APK.
// Never trust a redirect_to supplied by the client.
export const AUTH_CALLBACK_URL = new URL(
  '/auth/callback',
  process.env.APP_URL ?? 'https://mapo-experiencias-api.vercel.app',
).toString();
export function authEmailRedirect(action: string, body?: Record<string, unknown>) {
  const flow = action === 'recover' ? 'recovery'
    : action === 'signup' ? 'signup'
    : action === 'user' ? 'email_change'
    : action === 'resend' && body?.type === 'email_change' ? 'email_change'
    : action === 'resend' ? 'signup' : undefined;
  return AUTH_CALLBACK_URL + (flow ? `?flow=${flow}` : '');
}
