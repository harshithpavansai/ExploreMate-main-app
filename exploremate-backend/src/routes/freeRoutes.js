const express = require('express');
const router = express.Router();
const axios = require('axios');

// google-tts-api requires no API key and returns a direct Google Translate TTS audio URL
let googleTTS;
try {
  googleTTS = require('google-tts-api');
} catch (e) {
  // Safe mock if dependency is not installed yet
  googleTTS = {
    getAudioUrl: (text, opts) => `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(text)}&tl=${opts.lang || 'en'}&client=tw-ob`
  };
}

// @route   GET api/v1/free/weather
// @desc    Get free weather data (Open-Meteo API - NO KEY REQUIRED)
router.get('/weather', async (req, res) => {
    try {
        const { lat = 17.6868, lon = 83.2185 } = req.query; // Default to Vizag
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true`;
        
        const response = await axios.get(url);
        res.json({ weather: response.data.current_weather });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ msg: 'Weather fetch failed' });
    }
});

// @route   GET api/v1/free/places
// @desc    Get free places/food data (Nominatim/OpenStreetMap - NO KEY REQUIRED)
router.get('/places', async (req, res) => {
    try {
        const { query = 'restaurant', city = 'Visakhapatnam' } = req.query;
        // Nominatim requires a User-Agent header
        const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}+in+${encodeURIComponent(city)}&format=json&limit=5`;
        
        const response = await axios.get(url, {
            headers: { 'User-Agent': 'ExploreMateApp/1.0' }
        });
        
        res.json({ places: response.data });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ msg: 'Places fetch failed' });
    }
});

// @route   GET api/v1/free/tts
// @desc    Get free Text-to-Speech audio URL (Google TTS API - NO KEY REQUIRED)
router.get('/tts', async (req, res) => {
    try {
        const { text, lang = 'en' } = req.query;
        if (!text) return res.status(400).json({ msg: 'Text is required' });

        // google-tts-api has a strict 200 character limit per request.
        // We truncate the text to the last space before 200 characters to prevent RangeError.
        let speechText = text;
        if (speechText.length >= 200) {
            speechText = speechText.substring(0, 199);
            const lastSpace = speechText.lastIndexOf(' ');
            if (lastSpace > 0) {
                speechText = speechText.substring(0, lastSpace);
            }
        }

        // Return a proxy URL pointing to our local streaming endpoint to bypass User-Agent blocks
        const localPlayUrl = `${req.protocol}://${req.get('host')}${req.baseUrl}/tts/play?text=${encodeURIComponent(speechText)}&lang=${lang}`;
        res.json({ audioUrl: localPlayUrl });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ msg: 'TTS generation failed' });
    }
});

// @route   GET api/v1/free/tts/play
// @desc    Stream the Text-to-Speech audio bytes directly (proxied to bypass Google block)
router.get('/tts/play', async (req, res) => {
    try {
        const { text, lang = 'en' } = req.query;
        if (!text) return res.status(400).json({ msg: 'Text is required' });

        let speechText = text;
        if (speechText.length >= 200) {
            speechText = speechText.substring(0, 199);
            const lastSpace = speechText.lastIndexOf(' ');
            if (lastSpace > 0) {
                speechText = speechText.substring(0, lastSpace);
            }
        }

        const url = googleTTS.getAudioUrl(speechText, {
            lang: lang,
            slow: false,
            host: 'https://translate.google.com',
        });

        // Fetch audio stream from Google with browser User-Agent
        const response = await axios({
            method: 'get',
            url: url,
            responseType: 'stream',
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            }
        });

        res.setHeader('Content-Type', 'audio/mpeg');
        response.data.pipe(res);
    } catch (err) {
        console.error('TTS proxy play failed:', err.message);
        res.status(500).json({ msg: 'Audio streaming failed' });
    }
});

module.exports = router;
