/**
 * Google Translate wrapper.
 * Falls back to a no-op pass-through (with detected language echoed) when no key is set.
 */
const axios = require('axios');
const logger = require('../utils/logger');
const openaiService = require('./openaiService');

const KEY = process.env.GOOGLE_TRANSLATE_API_KEY;
const BASE = 'https://translation.googleapis.com/language/translate/v2';

const translate = async ({ text, target = 'en', source }) => {
  if (!text) return { translated: '', detectedSourceLanguage: 'en' };

  // 1. Try OpenAI Translation
  try {
    const messages = [
      {
        role: 'user',
        content: `Translate this text to target language code "${target}". Respond ONLY with the translation, no extra text, notes, explanations or quotes. Text:\n${text}`
      }
    ];
    const system = 'You are an expert translator. Translate the user text accurately to the target language.';
    const reply = await openaiService.chat({ messages, system });
    if (reply && reply.content) {
      return {
        translated: reply.content.trim(),
        detectedSourceLanguage: source || 'auto'
      };
    }
  } catch (openaiErr) {
    logger.warn(`OpenAI translate failed: ${openaiErr.message}`);
  }

  // 2. Try Google Translate API (with GCP Key)
  if (KEY) {
    try {
      const { data } = await axios.post(`${BASE}?key=${KEY}`,
        { q: text, target, ...(source ? { source } : {}), format: 'text' },
        { timeout: 5000 }
      );
      const t = data.data.translations[0];
      return { translated: t.translatedText, detectedSourceLanguage: t.detectedSourceLanguage || source || 'auto' };
    } catch (err) {
      logger.warn(`Google Translate API key error: ${err.message}`);
    }
  }

  // 3. Fallback to Free Google Translate Web API (No Key Required!)
  try {
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${target}&dt=t&q=${encodeURIComponent(text)}`;
    const { data } = await axios.get(url, { timeout: 6000 });
    if (data && data[0] && data[0][0] && data[0][0][0]) {
      return {
        translated: data[0][0][0],
        detectedSourceLanguage: data[2] || source || 'auto',
        isFreeWeb: true
      };
    }
  } catch (freeErr) {
    logger.warn(`Free Translate API failed: ${freeErr.message}`);
  }

  // 4. Final mock fallback if all else fails
  return {
    translated: `[mock-${target}] ${text}`,
    detectedSourceLanguage: source || 'en',
    mock: true
  };
};

const supportedLanguages = () => ([
  { code: 'en', name: 'English' },  { code: 'es', name: 'Spanish' },
  { code: 'fr', name: 'French' },   { code: 'de', name: 'German' },
  { code: 'hi', name: 'Hindi' },    { code: 'ja', name: 'Japanese' },
  { code: 'zh', name: 'Chinese' },  { code: 'ar', name: 'Arabic' },
  { code: 'pt', name: 'Portuguese' },{ code: 'ru', name: 'Russian' },
  { code: 'it', name: 'Italian' },  { code: 'ko', name: 'Korean' },
  { code: 'te', name: 'Telugu' },   { code: 'ta', name: 'Tamil' },
]);

module.exports = { translate, supportedLanguages };
