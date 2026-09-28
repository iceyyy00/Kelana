import { getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

export async function requireAuth(req, res, next) {
  if (!process.env.K_SERVICE && getApps().length === 0) {
    req.user = { uid: 'local-development' };
    return next();
  }

  const authorization = req.headers.authorization || '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return res.status(401).json({ success: false, error: 'Authentication is required.' });
  }

  if (getApps().length === 0) {
    return res.status(401).json({ success: false, error: 'Authentication is unavailable.' });
  }

  try {
    req.user = await getAuth().verifyIdToken(match[1]);
    return next();
  } catch (error) {
    console.warn('[Auth] Rejected invalid Firebase ID token:', error.message);
    return res.status(401).json({ success: false, error: 'Invalid or expired authentication token.' });
  }
}
