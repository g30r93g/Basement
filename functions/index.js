const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.appleMusicAuthorizationToken = functions.https.onCall((data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('failed-precondition', 'Authorization token can only be obtained by authed users.');
    } else {
        var jwt = require('apple-music-jwt');
    
        var keyID = 'YU9A62HSN6';
        var teamID = '3V93A3ACV9';
        var secret = 'MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgwc1AmPEj19FsQgoKRFAcHgBa4MgYWX0KExrXDgROVtygCgYIKoZIzj0DAQehRANCAAQZRcRmfuO9uhZzNK2pVsVFFhkfEnic5nQRZhHydpBNf3pguhb8BNwKSRlv4n4FfgK90qmTmVrpsfWWmH4FZqsV';
    
        var token = jwt.generate(keyID, teamID, secret);
    
        return {
            "authToken" : token
        }
    }
});