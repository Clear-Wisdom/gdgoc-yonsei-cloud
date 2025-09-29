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

const toSerializableComment = (doc) => {
  const data = doc.data() || {};
  const createdAt = data.createdAt;
  return {
    id: data.id || doc.id,
    content: data.content || '',
    createdAt: createdAt ? createdAt.toDate().toISOString() : null,
  };
};

exports.read = async (req, res) => {
  const origin = getAllowedOrigin(req.get('Origin'));
  res.set('Access-Control-Allow-Origin', origin);
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Max-Age', '3600');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed. Use GET.' });
  }

  try {
    const snapshot = await commentsCollection().get();
    const comments = snapshot.docs.map(toSerializableComment);
    return res.status(200).json({ comments });
  } catch (error) {
    console.error('Read comments failed:', error);
    const errorMessage = error.message || 'An unknown error occurred.';
    return res.status(500).json({ 
        error: 'Failed to read comments.',
        details: errorMessage,
        stack: error.stack
    });
  }
};