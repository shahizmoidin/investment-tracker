const admin = require('firebase-admin');

// Initialize the Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: 'https://payment-remainder-beff0.firebaseio.com'
});

// The UID of the user to update.
const uid = 'GfkTnEHrFZORZDsK35L4inh9lHK2';

// Set admin custom claim for the user
admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log('Custom claims set for user', uid);
    process.exit(0);
  })
  .catch(error => {
    console.error('Error setting custom claims:', error);
    process.exit(1);
  });
