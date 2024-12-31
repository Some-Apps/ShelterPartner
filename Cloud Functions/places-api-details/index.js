const functions = require('@google-cloud/functions-framework');
const axios = require('axios');
const cors = require('cors')({ origin: true });  // Import cors

// Cloud Function to fetch Place Details
functions.http('getPlaceDetails', (req, res) => {
  cors(req, res, async () => {
    const placeId = req.query.place_id;
    try {
      const response = await axios.get(`https://maps.googleapis.com/maps/api/place/details/json`, {
        params: {
          place_id: placeId,
          key: 'key',  // Replace with your actual API key
        },
      });
      res.json(response.data);
    } catch (error) {
      res.status(500).send('Error fetching place details');
    }
  });
});
