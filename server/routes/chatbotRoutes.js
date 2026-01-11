const express = require('express');
const router = express.Router();
const chatbotController = require('../controllers/chatbotController');
const { protect } = require('../middlewares/authMiddleware');
const { check } = require('express-validator');

// Apply authentication middleware to all routes
router.use(protect);

// @desc    Send message to AI chatbot
// @route   POST /api/chatbot/message
// @access  Private
router.post(
    '/message',
    [
        check('message')
            .trim()
            .isLength({ min: 1 })
            .withMessage('Tin nhắn không được để trống')
    ],
    chatbotController.sendMessage
);

// @desc    Get chat history
// @route   GET /api/chatbot/history
// @access  Private
router.get('/history', chatbotController.getChatHistory);

// @desc    Clear chat history
// @route   DELETE /api/chatbot/history
// @access  Private
router.delete('/history', chatbotController.clearChatHistory);

module.exports = router;
