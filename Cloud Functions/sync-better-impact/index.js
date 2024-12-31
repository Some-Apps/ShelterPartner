const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios'); // Using axios for HTTP requests
const cors = require('cors')({ origin: true }); // Enable CORS

admin.initializeApp();

exports.syncBetterImpact = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    // // Verify Firebase ID token
    // const idToken = req.headers.authorization?.split('Bearer ')[1];

    // if (!idToken) {
    //   return res.status(401).send('Unauthorized');
    // }

    // try {
    //   const decodedToken = await firebaseAdmin.auth().verifyIdToken(idToken);
    //   // Proceed with the rest of your function
    // } catch (error) {
    //   console.error('Error verifying ID token:', error);
    //   return res.status(401).send('Unauthorized');
    // }


    // Extract username and password from the request body
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).send('Username and password are required.');
    }

    try {
      // Encode credentials for Basic Auth
      const basicAuth = Buffer.from(`${username}:${password}`).toString('base64');

      // Make the request to the Better Impact API
      const response = await axios.get('https://api.betterimpact.com/v1/organization/users/', {
        headers: {
          'Authorization': `Basic ${basicAuth}`,
        },
      });

      // Return the response data
      return res.status(200).json(response.data);
    } catch (error) {
      console.error('Error fetching data from Better Impact API:', error);

      // Handle different error scenarios
      if (error.response) {
        // The request was made, and the server responded with a status code
        return res.status(error.response.status).send(error.response.data);
      } else if (error.request) {
        // The request was made, but no response was received
        return res.status(500).send('No response received from Better Impact API.');
      } else {
        // Something happened in setting up the request
        return res.status(500).send('Error in making request to Better Impact API.');
      }
    }
  });
});
