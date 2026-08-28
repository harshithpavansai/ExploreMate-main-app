/**
 * AI Assist screen + smart travel tools backend.
 */
const { ok, ApiError, asyncHandler } = require('../utils/responseHandler');
const ai = require('../services/openaiService');
const weather = require('../services/weatherService');

// POST /ai/chat   { messages:[{role,content}], system? }
const chat = asyncHandler(async (req, res) => {
  const { messages, system } = req.body;
  if (!Array.isArray(messages) || !messages.length) throw new ApiError('messages array required');
  const reply = await ai.chat({ messages, system });
  return ok(res, reply);
});

// POST /ai/recommend   { city, interests, weather?, time? }
const recommend = asyncHandler(async (req, res) => {
  const { city, interests = [], time } = req.body;
  if (!city) throw new ApiError('city required');
  let w = req.body.weather;
  if (!w) {
    const fetched = await weather.fetchWeather({ city });
    w = `${fetched.condition}, ${fetched.temp_c}C`;
  }
  const out = await ai.recommendPlaces({
    city,
    interests: Array.isArray(interests) ? interests.join(', ') : interests,
    weather: w,
    time: time || new Date().toISOString(),
  });
  return ok(res, out);
});

// POST /ai/travel-tips   { destination, days, interests }
const travelTips = asyncHandler(async (req, res) => {
  const { destination, days = 3, interests = [] } = req.body;
  if (!destination) throw new ApiError('destination required');
  const messages = [{
    role: 'user',
    content: `Give 5 short, actionable travel tips for a ${days}-day trip to ${destination}` +
             ` focused on ${(Array.isArray(interests) ? interests.join(', ') : interests) || 'general travel'}.`,
  }];
  const reply = await ai.chat({ messages, system: 'You are a concise, expert travel advisor.' });
  return ok(res, reply);
});

// POST /ai/schedule   { destination, days, budget }
const generateSchedule = asyncHandler(async (req, res) => {
  const { destination, days = 4, budget } = req.body;
  if (!destination) throw new ApiError('destination required');
  const itinerary = await ai.generateItinerary({
    destination,
    startDate: null,
    endDate: null,
    travelers: 1,
    interests: [],
    budget: budget ? `${budget}` : 'flexible',
  });
  return res.status(200).json({ success: true, itinerary });
});

// POST /ai/audio-narration   { place, question }
const getAudioNarration = asyncHandler(async (req, res) => {
  const { place, question } = req.body;
  if (!place) throw new ApiError('place required');
  
  let narration;
  if (question) {
    const reply = await ai.chat({
      messages: [{
        role: 'user',
        content: `Answer this question about "${place}": ${question}`
      }],
      system: 'You are ExploreMate, a friendly AI travel assistant.'
    });
    narration = reply.content;
  } else {
    narration = await ai.generateAudioTourScript({
      destinationName: place,
      durationMinutes: 3,
    });
  }
  return res.status(200).json({ success: true, narration });
});

module.exports = { chat, recommend, travelTips, generateSchedule, getAudioNarration };
