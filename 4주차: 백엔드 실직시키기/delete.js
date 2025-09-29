const { Firestore } = require('@google-cloud/firestore');

const firestore = new Firestore({ databaseId: 'test-database' });
const COLLECTION_NAME = 'commentApp';
const DOCUMENT_ID = 'arS5HKzyajR0p1fVPbFj';

const commentsCollection = () =>
  firestore.collection(COLLECTION_NAME).doc(DOCUMENT_ID).collection('comments');

const customAllowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const allowedOrigins = [
  ...new Set([
    'https://storage.googleapis.com', // The origin for the frontend
    ...customAllowedOrigins,
  ]),
];

const getAllowedOrigin = (origin) => {
  if (allowedOrigins.length === 0 || allowedOrigins.includes('*')) {
    return '*';
  }
  if (origin && allowedOrigins.includes(origin)) {
    return origin;
  }
  return allowedOrigins[0];
};

exports.delete = async (req, res) => {
  const origin = getAllowedOrigin(req.get('Origin'));
  res.set('Access-Control-Allow-Origin', origin);
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Max-Age', '3600');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  if (req.method !== 'DELETE') {
    return res.status(405).json({ error: 'Method Not Allowed. Use DELETE.' });
  }

  try {
    const idFromBody = req.body && typeof req.body.id === 'string' ? req.body.id.trim() : '';
    const idFromQuery = typeof req.query.id === 'string' ? req.query.id.trim() : '';
    const id = idFromBody || idFromQuery;

    if (!id) {
      return res.status(400).json({ error: 'id is required.' });
    }

    const docRef = commentsCollection().doc(id);
    const snapshot = await docRef.get();

    if (!snapshot.exists) {
      return res.status(404).json({ error: 'Comment not found.' });
    }

    await docRef.delete();

    return res.status(200).json({ id });
  } catch (error) {
    console.error('Delete comment failed:', error);
    return res.status(500).json({ error: 'Failed to delete comment.' });
  }
};