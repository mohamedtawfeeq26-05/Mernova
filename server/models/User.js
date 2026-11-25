const mongoose = require('mongoose')
const bcrypt = require('bcryptjs')

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },
    password: {
      type: String,
      required: true
    },
    phone: {
      type: String,
      required: true
    },
    role: {
      type: String,
      enum: ['donor', 'requester', 'admin'],
      default: 'donor'
    },

    // Donor Specific Fields
    bloodGroup: {
      type: String,
      enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
    },
    age: {
      type: Number,
      min: 18
    },
    gender: {
      type: String
    },
    city: {
      type: String,
      trim: true
    },
    address: {
      type: String
    },
    pincode: {
      type: String
    },
    location: {
      type: {
        type: String,
        enum: ['Point']
      },
      coordinates: {
        type: [Number]
      }
    },

    // Availability Management
    availability: {
      type: String,
      enum: ['Available', 'Unavailable'],
      default: 'Available'
    },
    lastDonationDate: {
      type: Date
    },
    nextEligibleDate: {
      type: Date
    },
    totalDonations: {
      type: Number,
      default: 0
    },
    lastReminderSentAt: {
      type: Date
    }
  },
  { timestamps: true }
)

// Index for geo and search
userSchema.index({ bloodGroup: 1, city: 1, availability: 1 })

// Hash password before saving
userSchema.pre('save', async function () {
  if (this.isModified('password')) {
    const salt = await bcrypt.genSalt(10)
    this.password = await bcrypt.hash(this.password, salt)
  }

  // Calculate next eligible date when lastDonationDate changes
  if (this.isModified('lastDonationDate') && this.lastDonationDate) {
    const DONATION_COOLDOWN_DAYS = 90 // 90 days cooldown period
    const eligibleDate = new Date(this.lastDonationDate)
    eligibleDate.setDate(eligibleDate.getDate() + DONATION_COOLDOWN_DAYS)
    this.nextEligibleDate = eligibleDate

    // If cooldown is still in effect, auto-update availability to Unavailable
    if (new Date() < eligibleDate) {
      this.availability = 'Unavailable'
    }
  }
})

// Compare password method
userSchema.methods.comparePassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password)
}

const User = mongoose.model('User', userSchema)

module.exports = User
