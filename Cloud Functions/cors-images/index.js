const functions = require('@google-cloud/functions-framework');
const axios = require('axios');

functions.http('imageProxy', async (req, res) => {
  const imageUrl = req.query.url;
  if (!imageUrl) {
    res.status(400).send('No image URL provided.');
    return;
  }

  try {
    const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
    const contentType = response.headers['content-type'] || 'image/jpeg';

    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    // If needed, you can also add:
    // res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    // res.set('Access-Control-Allow-Headers', 'Content-Type');

    res.set('Content-Type', contentType);
    res.status(200).send(response.data);
  } catch (error) {
    console.error('Error fetching image:', error);
    res.status(500).send('Failed to fetch image.');
  }
});