const express = require('express')
const router = express.Router()
const User = require('../models/User')
const { verifyToken, authorizeRoles } = require('../middleware/auth')
const { checkAndSendAvailabilityReminders } = require('../services/notificationService')

// ----------------------------------------------------
// SEARCH / LIST DONORS (Public or Authenticated)
// ----------------------------------------------------
router.get('/search', async (req, res) => {
  try {
    const { bloodGroup, city, availability } = req.query

    const filter = { role: 'donor' }

    if (bloodGroup) {
      filter.bloodGroup = bloodGroup
    }

    if (city) {
      filter.city = { $regex: city, $options: 'i' }
    }

    if (availability) {
      filter.availability = availability
    }

    const donors = await User.find(filter)
      .select('-password')
      .sort({ availability: 1, createdAt: -1 })

    res.status(200).json({
      success: true,
      count: donors.length,
      donors
    })
  } catch (error) {
    console.error('Donor search error:', error)
    res.status(500).json({
      success: false,
      message: 'Failed to search donors',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// GET ALL DONORS
// ----------------------------------------------------
router.get('/', async (req, res) => {
  try {
    const donors = await User.find({ role: 'donor' })
      .select('-password')
      .sort({ createdAt: -1 })

    res.status(200).json({
      success: true,
      count: donors.length,
      donors
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch donors',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// GET DONOR AVAILABILITY STATUS (For logged-in donor)
// ----------------------------------------------------
router.get('/availability/me', verifyToken, authorizeRoles('donor'), async (req, res) => {
  try {
    const donor = await User.findById(req.user._id).select('-password')

    const now = new Date()
    let daysRemaining = 0
    let isCoolingDown = false

    if (donor.nextEligibleDate && donor.nextEligibleDate > now) {
      isCoolingDown = true
      const diffMs = donor.nextEligibleDate - now
      daysRemaining = Math.ceil(diffMs / (1000 * 60 * 60 * 24))
    }

    res.status(200).json({
      success: true,
      availability: donor.availability,
      lastDonationDate: donor.lastDonationDate,
      nextEligibleDate: donor.nextEligibleDate,
      isCoolingDown,
      daysRemaining,
      totalDonations: donor.totalDonations || 0
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Unable to retrieve availability status',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// UPDATE DONOR AVAILABILITY & LAST DONATION DATE
// ----------------------------------------------------
router.put('/availability', verifyToken, authorizeRoles('donor'), async (req, res) => {
  try {
    const { availability, lastDonationDate, incrementDonationCount } = req.body

    const donor = await User.findById(req.user._id)
    if (!donor) {
      return res.status(404).json({
        success: false,
        message: 'Donor record not found.'
      })
    }

    // If last donation date is provided/updated
    if (lastDonationDate) {
      const parsedDate = new Date(lastDonationDate)
      donor.lastDonationDate = parsedDate

      // Calculate next eligibility (90 days cooldown)
      const eligibleDate = new Date(parsedDate)
      eligibleDate.setDate(eligibleDate.getDate() + 90)
      donor.nextEligibleDate = eligibleDate

      if (incrementDonationCount) {
        donor.totalDonations = (donor.totalDonations || 0) + 1
      }

      // If cool-down date is in future, force Unavailable
      if (new Date() < eligibleDate) {
        donor.availability = 'Unavailable'
      } else if (availability) {
        donor.availability = availability
      }
    } else if (availability) {
      // Check if cooldown allows switching to Available
      if (availability === 'Available' && donor.nextEligibleDate && new Date() < donor.nextEligibleDate) {
        return res.status(400).json({
          success: false,
          message: `Cannot set status to Available yet. Next eligible donation date is ${donor.nextEligibleDate.toLocaleDateString()}.`
        })
      }
      donor.availability = availability
    }

    await donor.save()

    const sanitized = donor.toObject()
    delete sanitized.password

    res.status(200).json({
      success: true,
      message: 'Donor availability updated successfully!',
      donor: sanitized
    })
  } catch (error) {
    console.error('Update availability error:', error)
    res.status(500).json({
      success: false,
      message: 'Failed to update availability',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// UPDATE DONOR PROFILE (Address, City, PIN, Phone)
// ----------------------------------------------------
router.put('/profile', verifyToken, async (req, res) => {
  try {
    const { name, phone, city, address, pincode } = req.body
    const user = await User.findById(req.user._id)
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' })
    }

    if (name) user.name = name
    if (phone) user.phone = phone
    if (city) user.city = city
    if (address) user.address = address
    if (pincode) user.pincode = pincode

    await user.save()

    const sanitized = user.toObject()
    delete sanitized.password

    res.status(200).json({
      success: true,
      message: 'Address and profile updated successfully!',
      user: sanitized
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// TRIGGER AUTOMATIC AVAILABILITY REMINDERS (Cron / Manual)
// ----------------------------------------------------
router.post('/availability/reminders/trigger', async (req, res) => {
  try {
    const result = await checkAndSendAvailabilityReminders()
    res.status(200).json({
      success: true,
      message: 'Availability reminder check completed.',
      result
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to run availability reminder job',
      error: error.message
    })
  }
})

module.exports = router
