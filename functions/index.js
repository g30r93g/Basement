const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp(functions.config().firebase);

const db = admin.firestore();

// MARK: - Internal Functions
exports.newSessionStarted = functions.firestore.document("/Sessions/{sessionID}").onCreate(async (snap, context) => {
    /// Adds host details into session details and makes this the running session for the current user.

    const sessionID = context.params.sessionID;
    const userID = snap.data().details.host.information.identifier;

    // Fetch user details and populate into host object in session
    const userDocumentRef = db.collection('Users').doc(userID);
    var userDocument = await userDocumentRef.get();
    var userProfile = userDocument.data();

    console.log(`Updating session ${sessionID} to include information for ${userProfile.information.username} (User ID: ${userID})`)

    var newSession = userDocumentRef.update({
        "details.host.information" : userProfile.information
    });

    const userCurrentSessionCollection = userDocumentRef.collection('Session');
    const userCurrentSessionDocument = userCurrentSessionCollection.doc(userID);
    await firebase

    console.log(`Setting session ${sessionID} to be active session for user. All other sessions will be given an endTime timestamp.`)

    return null
});

// exports.sendSessionNotification = functions.firestore.document("/Sessions/{sessionID}").onCreate(async (snap, context) => {
//    /// Sends a notification to friends or relevant users about a new stream.
// });

// Fetch Apple Music Auth Token
// exports.appleMusicAuthorizationToken = functions.https.onCall((data, context) => {
//     if (!context.auth) {
//         throw new functions.https.HttpsError('failed-precondition', 'Authorization token can only be obtained by authed users.');
//     } else {
//         var jwt = require('apple-music-jwt');
    
//         var keyID = 'YU9A62HSN6';
//         var teamID = '3V93A3ACV9';
//         var secret = 'MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgwc1AmPEj19FsQgoKRFAcHgBa4MgYWX0KExrXDgROVtygCgYIKoZIzj0DAQehRANCAAQZRcRmfuO9uhZzNK2pVsVFFhkfEnic5nQRZhHydpBNf3pguhb8BNwKSRlv4n4FfgK90qmTmVrpsfWWmH4FZqsV';
    
//         var token = jwt.generate(keyID, teamID, secret);
    
//         return {
//             "authToken" : token
//         }
//     }
// });

// MARK: - Callable Functions

// Determine if username is available
exports.usernameAvailability = functions.https.onCall(async (data, context) => {
    let requestedUsername = data.requestedUsername;

    if (!(typeof requestedUsername === "string")) {
        throw new functions.https.HttpsError('invalid-argument', 'Username provided is badly formatted.');
    }

    const userCollection = db.collection('Users');

    var matchingUserDocumentSnapshot = await userCollection.where('username', '==', requestedUsername).get();

    const isAvailable = matchingUserDocumentSnapshot.size === 0;
    console.log(`Username ${requestedUsername} availability: ${isAvailable} (${matchingUserDocumentSnapshot.size} documents fetched)`)

    return {
        "requestedUsername" : requestedUsername,
        "isAvailable" : isAvailable
    }
});
