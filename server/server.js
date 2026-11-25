// BloodBridge Real-Time MERN Server
const http = require('http')
const express = require('express')
const mongoose = require('mongoose')
const cors = require('cors')
const { Server } = require('socket.io')
require('dotenv').config()

const User = require('./models/User')
const Donor = require('./models/Donor')
const { setIO, checkAndSendAvailabilityReminders } = require('./services/notificationService')

// Route Imports
const authRoutes = require('./routes/authRoutes')
const donorRoutes = require('./routes/donorRoutes')
const requestRoutes = require('./routes/requestRoutes')
const notificationRoutes = require('./routes/notificationRoutes')
const adminRoutes = require('./routes/adminRoutes')

const app = express()
const server = http.createServer(app)

// Socket.IO Setup
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  }
})

// Pass io to notification service
setIO(io)

// MIDDLEWARE
app.use(cors())
app.use(express.json())

// Real-Time Socket Connection Handling
io.on('connection', (socket) => {
  console.log(`⚡ Client connected via Socket.IO: ${socket.id}`)

  // Join personal user room for direct alerts
  socket.on('join_user_room', (userId) => {
    if (userId) {
      socket.join(`user_${userId}`)
      console.log(`👤 Socket ${socket.id} joined user_${userId}`)
    }
  })

  // Join blood group room for matched broadcast alerts
  socket.on('join_blood_room', (bloodGroup) => {
    if (bloodGroup) {
      socket.join(`blood_${bloodGroup}`)
      console.log(`🩸 Socket ${socket.id} joined blood_${bloodGroup}`)
    }
  })

  // Leave rooms
  socket.on('leave_user_room', (userId) => {
    if (userId) socket.leave(`user_${userId}`)
  })

  socket.on('disconnect', () => {
    console.log(`🔌 Client disconnected: ${socket.id}`)
  })
})

// BASE HEALTH CHECK API
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    message: 'BloodBridge Real-Time Backend with Socket.IO is Running!'
  })
})

// MOUNT ROUTERS
app.use('/api/auth', authRoutes)
app.use('/api/donors', donorRoutes)
app.use('/api/requests', requestRoutes)
app.use('/api/notifications', notificationRoutes)
app.use('/api/admin', adminRoutes)

// BACKWARD-COMPATIBLE DONOR REGISTRATION ENDPOINT
app.post('/api/donors/register', async (req, res) => {
  try {
    const {
      name,
      age,
      gender,
      bloodGroup,
      phone,
      email,
      password,
      city,
      address,
      pincode,
      location
    } = req.body

    // Check if user already exists in User collection
    let existing = await User.findOne({ email: email.toLowerCase() })
    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'A donor with this email already exists.'
      })
    }

    // Create in User model with default password if not provided
    const user = new User({
      name,
      age,
      gender,
      bloodGroup,
      phone,
      email: email.toLowerCase(),
      password: password || 'BloodDonor@123',
      city,
      address,
      pincode,
      location,
      role: 'donor',
      availability: 'Available'
    })

    await user.save()

    // Also persist in legacy Donor model for backward compatibility
    try {
      const legacyDonor = new Donor({
        name,
        age,
        gender,
        bloodGroup,
        phone,
        email: email.toLowerCase(),
        city,
        address,
        pincode,
        location,
        availability: 'Available'
      })
      await legacyDonor.save()
    } catch (e) {
      // Ignored if legacy schema differs or phone collision
    }

    res.status(201).json({
      success: true,
      message: 'Donor registered successfully!',
      donor: user
    })
  } catch (error) {
    console.error('Registration Error:', error.message)
    res.status(400).json({
      success: false,
      message: 'Registration failed',
      error: error.message
    })
  }
})

// BACKWARD-COMPATIBLE DONOR SEARCH ENDPOINT
app.get('/api/donors/search', async (req, res) => {
  try {
    const { bloodGroup, city, availability } = req.query
    const filter = { role: 'donor' }

    if (bloodGroup) filter.bloodGroup = bloodGroup
    if (city) filter.city = { $regex: city, $options: 'i' }
    if (availability) filter.availability = availability

    const donors = await User.find(filter).select('-password')

    res.status(200).json({
      success: true,
      count: donors.length,
      donors
    })
  } catch (error) {
    console.error('Search Error:', error.message)
    res.status(500).json({
      success: false,
      message: 'Donor search failed',
      error: error.message
    })
  }
})

// BACKGROUND CRON FOR AUTOMATIC AVAILABILITY REMINDERS (Runs every 1 hour)
const REMINDER_INTERVAL_MS = 60 * 60 * 1000
setInterval(() => {
  console.log('⏰ Running automatic donor availability reminder task...')
  checkAndSendAvailabilityReminders()
}, REMINDER_INTERVAL_MS)

// MONGODB CONNECTION & SERVER START
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/BloodBridge'
const PORT = process.env.PORT || 5000

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB Connected Successfully!')

    // Run initial availability check on server startup
    checkAndSendAvailabilityReminders()

    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`❌ Port ${PORT} is already in use by an active instance.`)
        console.log(`💡 Free port ${PORT} or specify PORT in .env (e.g., PORT=5001)`)
        process.exit(1)
      } else {
        console.error('❌ Server error:', err.message)
      }
    })

    server.listen(PORT, () => {
      console.log(`🚀 BloodBridge server with Socket.IO running on port ${PORT}`)
    })
  })
  .catch((error) => {
    console.error('❌ MongoDB Connection Error:', error.message)
  })

module.exports = { app, server, io }
