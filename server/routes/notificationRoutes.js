const express = require('express')
const router = express.Router()
const Notification = require('../models/Notification')
const { verifyToken } = require('../middleware/auth')

// ----------------------------------------------------
// GET CURRENT USER'S NOTIFICATIONS
// ----------------------------------------------------
router.get('/', verifyToken, async (req, res) => {
  try {
    const notifications = await Notification.find({ recipient: req.user._id })
      .populate('bloodRequest')
      .sort({ createdAt: -1 })
      .limit(50)

    const unreadCount = await Notification.countDocuments({
      recipient: req.user._id,
      read: false
    })

    res.status(200).json({
      success: true,
      unreadCount,
      notifications
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// MARK SINGLE NOTIFICATION AS READ
// ----------------------------------------------------
router.put('/:id/read', verifyToken, async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, recipient: req.user._id },
      { read: true },
      { new: true }
    )

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      })
    }

    res.status(200).json({
      success: true,
      notification
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update notification',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// MARK ALL NOTIFICATIONS AS READ
// ----------------------------------------------------
router.put('/read-all', verifyToken, async (req, res) => {
  try {
    await Notification.updateMany(
      { recipient: req.user._id, read: false },
      { read: true }
    )

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read'
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to mark notifications as read',
      error: error.message
    })
  }
})

module.exports = router
