const express = require('express')
const router = express.Router()
const User = require('../models/User')
const BloodRequest = require('../models/BloodRequest')
const Notification = require('../models/Notification')
const { verifyToken, authorizeRoles } = require('../middleware/auth')

// ----------------------------------------------------
// ADMIN DASHBOARD STATS
// ----------------------------------------------------
router.get('/stats', verifyToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const totalDonors = await User.countDocuments({ role: 'donor' })
    const availableDonors = await User.countDocuments({ role: 'donor', availability: 'Available' })
    const totalRequesters = await User.countDocuments({ role: 'requester' })
    const totalRequests = await BloodRequest.countDocuments()
    const pendingRequests = await BloodRequest.countDocuments({ status: 'Pending' })
    const emergencyRequests = await BloodRequest.countDocuments({
      urgency: { $in: ['Emergency', 'Critical'] },
      status: 'Pending'
    })
    const fulfilledRequests = await BloodRequest.countDocuments({ status: 'Fulfilled' })
    const acceptedRequests = await BloodRequest.countDocuments({ status: 'Accepted' })

    res.status(200).json({
      success: true,
      stats: {
        totalDonors,
        availableDonors,
        totalRequesters,
        totalRequests,
        pendingRequests,
        emergencyRequests,
        acceptedRequests,
        fulfilledRequests
      }
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch admin statistics',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// GET ALL USERS (Admin only)
// ----------------------------------------------------
router.get('/users', verifyToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 })
    res.status(200).json({
      success: true,
      users
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
      error: error.message
    })
  }
})

module.exports = router
