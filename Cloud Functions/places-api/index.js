const functions = require('@google-cloud/functions-framework');
const axios = require('axios');
const cors = require('cors')({ origin: true });  // Import cors

functions.http('getSuggestions', (req, res) => {
  cors(req, res, async () => {  // Wrap your function in the CORS middleware
    const input = req.query.input;
    try {
      const response = await axios.get(`https://maps.googleapis.com/maps/api/place/autocomplete/json`, {
        params: {
          input: input,
          key: 'key',  // Replace with your actual API key
          components: 'country:us',
        },
      });
      res.json(response.data);
    } catch (error) {
      res.status(500).send('Error fetching autocomplete data');
    }
  });
});
