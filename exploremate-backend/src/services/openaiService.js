/**
 * OpenAI service - travel chat, itinerary generation, audio-tour scripts.
 *
 * If OPENAI_API_KEY is not configured, methods fall back to deterministic mock
 * data so the rest of the system stays functional in development.
 */
const logger = require('../utils/logger');

let openai = null;
const apiKey = process.env.OPENAI_API_KEY;

if (apiKey) {
  try {
    const { OpenAI } = require('openai');
    openai = new OpenAI({ apiKey });
  } catch (err) {
    logger.warn(`OpenAI SDK not loaded: ${err.message}`);
  }
}

const MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';

const safeJsonExtract = (text) => {
  if (!text) return null;
  const match = text.match(/```json\s*([\s\S]*?)```/) || text.match(/(\{[\s\S]*\}|\[[\s\S]*\])/);
  try { return match ? JSON.parse(match[1] || match[0]) : JSON.parse(text); }
  catch { return null; }
};

// ----------------------------------------------------------------------
// Public API
// ----------------------------------------------------------------------

/**
 * Free-form travel chat (used by the AI Assist screen).
 */
const chat = async ({ messages, system }) => {
  if (!openai) {
    return {
      role: 'assistant',
      content:
        "I'm in offline demo mode. Connect an OpenAI key to enable real AI replies. " +
        "Meanwhile, try asking ExploreMate for hidden gems or weather-based food picks!",
    };
  }
  try {
    const completion = await openai.chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: system || 'You are ExploreMate, a friendly AI travel assistant.' },
        ...messages,
      ],
      temperature: 0.7,
    });
    return { role: 'assistant', content: completion.choices[0].message.content };
  } catch (err) {
    logger.warn(`OpenAI Chat API failed: ${err.message}. Falling back to offline guide replies.`);
    const lastUserMsg = messages[messages.length - 1]?.content || '';
    let responseText = "I had trouble reaching the OpenAI backend, but ExploreMate offline intelligence is here! ";
    if (lastUserMsg.toLowerCase().includes('audio') || lastUserMsg.toLowerCase().includes('chat') || lastUserMsg.toLowerCase().includes('guide')) {
      responseText += "To start an audio tour, tap 'Audio Tour Guide' from the side drawer or tap the 'Audio Tour' option on any destination card.";
    } else if (lastUserMsg.toLowerCase().includes('schedule') || lastUserMsg.toLowerCase().includes('plan') || lastUserMsg.toLowerCase().includes('trip')) {
      responseText += "To create an automated itinerary, head to the 'Trip Scheduler' from the drawer, type your city, and tap 'Generate New Plan'.";
    } else if (lastUserMsg.toLowerCase().includes('food') || lastUserMsg.toLowerCase().includes('restaurant')) {
      responseText += "To find places to eat, open the 'Food Explorer' page to select street food, cafes, or dining spots matching your mood.";
    } else {
      responseText += "Explore the live map on the 'Explore' tab or check out the 'City Game' page to earn XP by visiting hidden viewpoint gems.";
    }
    return {
      role: 'assistant',
      content: responseText,
    };
  }
};

/**
 * Generate a structured day-by-day itinerary.
 */
const generateItinerary = async ({ destination, startDate, endDate, travelers, interests, budget }) => {
  const prompt = `Create a JSON travel itinerary for the following trip:
Destination: ${destination || 'unspecified'}
Dates: ${startDate || '?'} to ${endDate || '?'}
Travelers: ${travelers || 1}
Budget: ${budget || 'flexible'}
Interests: ${(interests || []).join(', ') || 'general'}

Respond ONLY with valid JSON of shape:
[
  { "day": 1, "date": "YYYY-MM-DD", "title": "...", "morning": "...", "afternoon": "...", "evening": "...", "highlights": ["..."], "estimated_cost": 0 }
]`;

  const mockItinerary = [
    { day: 1, date: startDate || 'Day 1', title: `Arrival in ${destination || 'City'}`,
      morning: 'Hotel check-in & light breakfast',
      afternoon: 'City orientation walk',
      evening: 'Local dinner spot near hotel',
      highlights: ['Old town', 'Sunset point'], estimated_cost: 50 },
    { day: 2, date: endDate || 'Day 2', title: 'Hidden gems',
      morning: 'Visit lesser-known landmark',
      afternoon: 'Cafe + local market',
      evening: 'Audio-tour stroll',
      highlights: ['Market', 'Cafe'], estimated_cost: 60 },
  ];

  if (!openai) {
    return mockItinerary;
  }

  try {
    const completion = await openai.chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: 'You are an expert travel planner. Return ONLY valid JSON.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.6,
    });
    const parsed = safeJsonExtract(completion.choices[0].message.content);
    return parsed || mockItinerary;
  } catch (err) {
    logger.warn(`OpenAI Generate Itinerary failed: ${err.message}. Returning mock itinerary.`);
    return mockItinerary;
  }
};

const MOCK_SCRIPTS = {
  'gateway of india': 
    "Welcome to the iconic Gateway of India in Mumbai! Built in 1924 to commemorate the landing of King George V and Queen Mary, this spectacular basalt arch stands 26 meters tall. It overlooks the Arabian Sea and serves as the starting point for boats to Elephanta Caves. Notice the blend of Hindu and Muslim architectural styles, known as Indo-Saracenic, which makes this monument a unique symbol of Mumbai's rich history.",
  'borra caves':
    "Welcome to the breathtaking Borra Caves in the Ananthagiri hills of Visakhapatnam! Discovered in 1807 by William King, these limestone caves are estimated to be over 150 million years old. As you walk inside, marvel at the stunning stalactite and stalagmitite formations, which have been naturally carved by the Gosthani River. Local legends say a cow fell through the caves, leading to the discovery of a sacred Shiva Lingam inside.",
  'charminar':
    "Welcome to the historic Charminar in the heart of Hyderabad! Built in 1591 by Sultan Muhammad Quli Qutb Shah to celebrate the end of a deadly plague, this monumental mosque stands as a signature of Islamic architecture. The four minarets rise to a height of 56 meters. Stroll through the bustling Laad Bazaar nearby and take in the aroma of Hyderabadi pearls and traditional perfumes.",
  'old harbor walk':
    "Welcome to the serene Old Harbor Walk in Fort Kochi, Kerala! This historic path takes you along the beach where the famous giant Chinese Fishing Nets have lined the waters since the 14th century. As you walk, feel the sea breeze and observe the colonial-era houses, Dutch ruins, and old spice warehouses that tell the stories of Kochi's history as a global trade hub.",
  'amber fort':
    "Welcome to the majestic Amber Fort in Jaipur, Rajasthan! Built in 1592 by Raja Man Singh I, this massive hilltop fortress is known for its artistic style elements, blending Rajput and Mughal design. Walk through the grand courtyards, visit the stunning Sheesh Mahal (Mirror Palace) where a single candle can light up the entire room, and enjoy the panoramic views of Maota Lake below.",
  'eiffel tower':
    "Welcome to the Eiffel Tower in Paris, France! Constructed in 1889 by Gustave Eiffel for the World's Fair, this 330-meter wrought-iron structure is one of the most recognized landmarks in the world. Enjoy the view of the Champ de Mars and learn how this tower, originally intended to be dismantled after 20 years, became a crucial radio antenna and an immortal symbol of France.",
  'tokyo tower':
    "Welcome to Tokyo Tower in Japan! Standing at 332.9 meters, this self-supporting steel tower was built in 1958 and is inspired by the Eiffel Tower in Paris. It is painted in white and international orange to comply with aviation safety laws. Take in the spectacular views of the Tokyo skyline, and on a clear day, look out for the silhouette of Mount Fuji in the distance."
};

/**
 * Generate an audio-tour transcript for a destination.
 */
const generateAudioTourScript = async ({ destinationName, city, country, durationMinutes = 5, language = 'en' }) => {
  const prompt = `Write an engaging ${durationMinutes}-minute audio tour script in ${language} for "${destinationName}" in ${city}, ${country}. Cover history, culture, fun facts, and travel tips. Use a warm conversational tone. Plain text only.`;

  const getMockScript = () => {
    const key = String(destinationName || '').toLowerCase().trim();
    if (MOCK_SCRIPTS[key]) {
      return MOCK_SCRIPTS[key];
    }
    // Substring match
    for (const [k, v] of Object.entries(MOCK_SCRIPTS)) {
      if (key.includes(k) || k.includes(key)) {
        return v;
      }
    }
    return `Welcome to ${destinationName} in ${city || 'India'}, ${country || 'Asia'}! ` +
           `As you stand here today, imagine the centuries of stories these stones could tell. ` +
           `This place blends history, culture, and local life into one unforgettable experience. ` +
           `Take a deep breath, look around, and let ExploreMate guide your senses through every detail.`;
  };

  if (!openai) {
    return getMockScript();
  }
  try {
    const completion = await openai.chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: 'You are an expert audio tour scriptwriter for travelers.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.85,
    });
    return completion.choices[0].message.content.trim();
  } catch (err) {
    logger.warn(`OpenAI Audio Script failed: ${err.message}. Returning mock script.`);
    return getMockScript();
  }
};

/**
 * Recommend places given user preferences + context.
 */
const recommendPlaces = async ({ city, interests, weather, time }) => {
  const mockRecs = {
    recommendations: [
      { name: 'Old Town Stroll', reason: 'Charming streets and easy to explore on foot.' },
      { name: 'Sunset Viewpoint', reason: 'Best photo opportunity at golden hour.' },
      { name: 'Hidden Cafe', reason: 'Local favourite tucked away from tourists.' },
    ],
  };

  if (!openai) {
    return mockRecs;
  }
  try {
    const completion = await openai.chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: 'Travel concierge. Reply only with JSON: { "recommendations":[{name,reason}] }' },
        { role: 'user', content: `City: ${city}\nInterests: ${interests}\nWeather: ${weather}\nTime: ${time}` },
      ],
      temperature: 0.7,
    });
    return safeJsonExtract(completion.choices[0].message.content) || mockRecs;
  } catch (err) {
    logger.warn(`OpenAI Recommend Places failed: ${err.message}. Returning mock recs.`);
    return mockRecs;
  }
};

module.exports = { chat, generateItinerary, generateAudioTourScript, recommendPlaces };
