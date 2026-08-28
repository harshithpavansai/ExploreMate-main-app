const router = require('express').Router();
const ctrl = require('../controllers/aiController');
const { optionalAuth } = require('../middleware/authMiddleware');

router.use(optionalAuth);
router.post('/chat', ctrl.chat);
router.post('/recommend', ctrl.recommend);
router.post('/travel-tips', ctrl.travelTips);
router.post('/schedule', ctrl.generateSchedule);
router.post('/audio-narration', ctrl.getAudioNarration);

module.exports = router;
