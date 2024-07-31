const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.addAdminClaim = functions.https.onCall(async (data, context) => {
  // Check that the request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "The function must be called while authenticated.",
    );
  }

  // Check if the requesting user has admin privileges
  const requester = await admin.auth().getUser(context.auth.uid);
  if (!requester.customClaims || !requester.customClaims.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "The function must be called by an admin.",
    );
  }

  const uid = data.uid;
  return admin
      .auth()
      .setCustomUserClaims(uid, {admin: true})
      .then(() => {
        return {
          message: `Success! ${uid} has been granted admin privileges.`,
        };
      })
      .catch((error) => {
        return {
          error: error.message,
        };
      });
});
