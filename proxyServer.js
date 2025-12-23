#!/usr/bin/env node
/**
 * Simple Gemini proxy server used by the Smart Ingredient Scanner app.
 *
 * Usage:
 *   1. Create a .env file that defines GEMINI_API_KEY=<your_key>.
 *   2. Install dependencies: npm install express axios dotenv
 *   3. Start the server: node proxyServer.js
 */
const express = require('express');
const axios = require('axios');
const dotenv = require('dotenv');

dotenv.config();

const { GEMINI_API_KEY, PORT = 4000 } = process.env;

if (!GEMINI_API_KEY) {
  console.error('Missing GEMINI_API_KEY environment variable. Exiting.');
  process.exit(1);
}

const app = express();
app.use(express.json({ limit: '10mb' }));

/**
 * POST /api/analyze
 * Body shape:
 * {
 *   "imageBase64": "<base64 string without data URI>",
 *   "prompt": "optional override instruction text"
 * }
 */
app.post('/api/analyze', async (req, res) => {
  const { imageBase64, prompt } = req.body || {};

  if (!imageBase64) {
    return res
      .status(400)
      .json({ error: 'imageBase64 is required in the request body.' });
  }

  const instruction =
    prompt ??
    'Analyze this ingredient label and return a structured summary including allergen warnings, nutritional highlights, and potential concerns.';

  const payload = {
    contents: [
      {
        role: 'user',
        parts: [
          { text: instruction },
          {
            inline_data: {
              mime_type: 'image/png',
              data: imageBase64,
            },
          },
        ],
      },
    ],
  };

  try {
    const response = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      payload,
      {
        params: { key: GEMINI_API_KEY },
        headers: { 'Content-Type': 'application/json' },
        timeout: 30_000,
      },
    );

    const textResponse =
      response.data?.candidates?.[0]?.content?.parts
        ?.map((part) => part.text)
        .join('\n') ?? 'No content returned.';

    return res.json({ result: textResponse });
  } catch (error) {
    const status = error.response?.status ?? 500;
    const message =
      error.response?.data ?? error.message ?? 'Unknown Gemini error.';

    console.error('Gemini API error:', message);
    return res
      .status(status)
      .json({ error: 'Failed to analyze image.', details: message });
  }
});

app.listen(PORT, () => {
  console.log(`Gemini proxy server listening on port ${PORT}`);
});

