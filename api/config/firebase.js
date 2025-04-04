const admin = require("firebase-admin");

const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function getTestToken() {
  try {
    const uid = 'test-user';  // ID test
    const customToken = await admin.auth().createCustomToken(uid);
    console.log('Test token:', customToken);
  } catch (error) {
    console.error('Error:', error);
  }
}

getTestToken();

const db = admin.firestore();
module.exports = db;