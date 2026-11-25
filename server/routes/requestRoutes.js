const express = require('express')
const router = express.Router()
const BloodRequest = require('../models/BloodRequest')
const User = require('../models/User')
const { verifyToken, authorizeRoles } = require('../middleware/auth')
const { notifyMatchingDonors, notifyRequestAccepted } = require('../services/notificationService')

// ----------------------------------------------------
// CREATE BLOOD REQUEST (Patient / Requester / Admin)
// ----------------------------------------------------
router.post('/', verifyToken, authorizeRoles('requester', 'admin'), async (req, res) => {
  try {
    const {
      patientName,
      hospitalName,
      bloodGroup,
      unitsRequired = 1,
      urgency = 'Normal',
      city,
      address,
      contactPhone,
      notes
    } = req.body

    if (!patientName || !hospitalName || !bloodGroup || !city || !address || !contactPhone) {
      return res.status(400).json({
        success: false,
        message: 'Please fill in all required request fields.'
      })
    }

    const newRequest = new BloodRequest({
      requester: req.user._id,
      patientName,
      hospitalName,
      bloodGroup,
      unitsRequired,
      urgency,
      city,
      address,
      contactPhone,
      notes,
      status: 'Pending'
    })

    await newRequest.save()

    // Trigger Real-Time Notifications (Socket.IO, Nodemailer, SMS API)
    // Runs asynchronously so API response is quick
    notifyMatchingDonors(newRequest).catch((err) =>
      console.error('Error dispatching notifications:', err)
    )

    res.status(201).json({
      success: true,
      message: `${urgency === 'Emergency' || urgency === 'Critical' ? '🚨 Emergency' : 'Standard'} blood request posted successfully! Matching donors are being alerted.`,
      bloodRequest: newRequest
    })
  } catch (error) {
    console.error('Create request error:', error)
    res.status(500).json({
      success: false,
      message: 'Failed to create blood request',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// GET ALL BLOOD REQUESTS (Public or Filtered)
// ----------------------------------------------------
// GET ACTIVE BLOOD REQUESTS
router.get('/', async (req, res) => {
  try {
    const { bloodGroup, city, urgency, status } = req.query

    // Cancelled requests are hidden by default
    const filter = {
      status: status || { $ne: 'Cancelled' }
    }

    if (bloodGroup) filter.bloodGroup = bloodGroup

    if (city) {
      filter.city = { $regex: city, $options: 'i' }
    }

    if (urgency) filter.urgency = urgency

    const requests = await BloodRequest.find(filter)
      .populate('requester', 'name phone email')
      .populate('acceptedBy', 'name phone bloodGroup')
      .sort({ createdAt: -1 })

    res.status(200).json({
      success: true,
      count: requests.length,
      requests
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch blood requests',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// GET MY REQUESTS (Requester created OR Donor accepted)
// ----------------------------------------------------
router.get('/my', verifyToken, async (req, res) => {
  try {
    let requests = []

    if (req.user.role === 'requester') {
      requests = await BloodRequest.find({ requester: req.user._id })
        .populate('acceptedBy', 'name phone bloodGroup email')
        .sort({ createdAt: -1 })
    } else if (req.user.role === 'donor') {
      requests = await BloodRequest.find({ acceptedBy: req.user._id })
        .populate('requester', 'name phone email')
        .sort({ acceptedAt: -1 })
    } else if (req.user.role === 'admin') {
      requests = await BloodRequest.find()
        .populate('requester', 'name phone email')
        .populate('acceptedBy', 'name phone bloodGroup')
        .sort({ createdAt: -1 })
    }

    res.status(200).json({
      success: true,
      requests
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch your requests',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// ACCEPT BLOOD REQUEST (Donor Accepts an Emergency / Pending Request)
// ----------------------------------------------------
router.put('/:id/accept', verifyToken, authorizeRoles('donor', 'admin'), async (req, res) => {
  try {
    const request = await BloodRequest.findById(req.params.id)

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Blood request not found.'
      })
    }

    if (request.status !== 'Pending') {
      return res.status(400).json({
        success: false,
        message: `This request is already marked as ${request.status}.`
      })
    }

    // Check donor availability
    const donor = await User.findById(req.user._id)
    if (donor.availability !== 'Available') {
      return res.status(400).json({
        success: false,
        message: 'Your current status is Unavailable. Please update your availability before accepting requests.'
      })
    }

    // Update request
    request.status = 'Accepted'
    request.acceptedBy = donor._id
    request.acceptedAt = new Date()
    await request.save()

    // Trigger Real-time notifications to the Requester
    notifyRequestAccepted({ bloodRequest: request, donor }).catch((err) =>
      console.error('Error notifying requester of acceptance:', err)
    )

    res.status(200).json({
      success: true,
      message: 'You have successfully accepted this blood request! The requester has been notified.',
      bloodRequest: request
    })
  } catch (error) {
    console.error('Accept request error:', error)
    res.status(500).json({
      success: false,
      message: 'Failed to accept blood request',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// UPDATE STATUS (Fulfilled / Cancelled)
// ----------------------------------------------------
router.put('/:id/status', verifyToken, async (req, res) => {
  try {
    const { status } = req.body
    const request = await BloodRequest.findById(req.params.id)

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Blood request not found.'
      })
    }

    // Check authorization: must be requester, admin, or donor who accepted
    const isOwner = request.requester.toString() === req.user._id.toString()
    const isAcceptedDonor = request.acceptedBy && request.acceptedBy.toString() === req.user._id.toString()
    const isAdmin = req.user.role === 'admin'

    if (!isOwner && !isAcceptedDonor && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to update the status of this request.'
      })
    }

    request.status = status
    await request.save()

    // If marked Fulfilled and donor accepted, can update donor's last donation date
    if (status === 'Fulfilled' && request.acceptedBy) {
      const donor = await User.findById(request.acceptedBy)
      if (donor) {
        donor.lastDonationDate = new Date()
        donor.totalDonations = (donor.totalDonations || 0) + 1
        await donor.save()
      }
    }

    res.status(200).json({
      success: true,
      message: `Request status updated to ${status}.`,
      bloodRequest: request
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update request status',
      error: error.message
    })
  }
})

module.exports = router
