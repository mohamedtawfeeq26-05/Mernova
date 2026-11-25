const express = require('express')
const router = express.Router()
const User = require('../models/User')
const { verifyToken, generateToken } = require('../middleware/auth')

// ----------------------------------------------------
// REGISTER (Donor, Requester, or Admin)
// ----------------------------------------------------
router.post('/register', async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      phone,
      role = 'donor',
      bloodGroup,
      age,
      gender,
      city,
      address,
      pincode,
      lastDonationDate
    } = req.body

    // Validation
    if (!name || !email || !password || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, password, and phone number are required.'
      })
    }

    // Role specific validation
    if (role === 'donor' && !bloodGroup) {
      return res.status(400).json({
        success: false,
        message: 'Blood group is required for donor registration.'
      })
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: email.toLowerCase() })
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'An account with this email address already exists.'
      })
    }

    // Create user
    const newUser = new User({
      name,
      email: email.toLowerCase(),
      password,
      phone,
      role,
      bloodGroup,
      age,
      gender,
      city,
      address,
      pincode,
      availability: role === 'donor' ? 'Available' : undefined,
      lastDonationDate: lastDonationDate ? new Date(lastDonationDate) : undefined
    })

    await newUser.save()

    // Generate token
    const token = generateToken(newUser)

    // Sanitize output
    const userJson = newUser.toObject()
    delete userJson.password

    res.status(201).json({
      success: true,
      message: `${role.charAt(0).toUpperCase() + role.slice(1)} account created successfully!`,
      token,
      user: userJson
    })
  } catch (error) {
    console.error('Registration error:', error)
    res.status(500).json({
      success: false,
      message: 'Registration failed.',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// LOGIN (Donor, Requester, Admin)
// ----------------------------------------------------
router.post('/login', async (req, res) => {
  try {
    const { email, password, role } = req.body

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required.'
      })
    }

    const user = await User.findOne({ email: email.toLowerCase() })
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      })
    }

    // Verify password
    const isMatch = await user.comparePassword(password)
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      })
    }

    // Optional role check
    if (role && user.role !== role) {
      return res.status(403).json({
        success: false,
        message: `This account is registered as '${user.role}', not '${role}'.`
      })
    }

    const token = generateToken(user)

    const userJson = user.toObject()
    delete userJson.password

    res.status(200).json({
      success: true,
      message: 'Login successful!',
      token,
      user: userJson
    })
  } catch (error) {
    console.error('Login error:', error)
    res.status(500).json({
      success: false,
      message: 'Login failed.',
      error: error.message
    })
  }
})

// ----------------------------------------------------
// GET CURRENT USER PROFILE (/me)
// ----------------------------------------------------
router.get('/me', verifyToken, async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      user: req.user
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Unable to fetch user profile.',
      error: error.message
    })
  }
})

module.exports = router
