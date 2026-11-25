
const mongoose = require('mongoose')

const donorSchema = new mongoose.Schema({

  name: {
    type: String,
    required: true,
    trim: true
  },

  age: {
    type: Number,
    required: true,
    min: 18
  },

  gender: {
    type: String,
    required: true
  },

  bloodGroup: {
    type: String,
    required: true,
    enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
  },

  phone: {
    type: String,
    required: true,
    unique: true
  },

  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },

  city: {
    type: String,
    required: true,
    trim: true
  },

  address: {
    type: String,
    required: true
  },

  pincode: {
    type: String,
    required: true
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

  availability: {
    type: String,
    enum: ['Available', 'Unavailable'],
    default: 'Unavailable'
  }

}, { timestamps: true })

// Geographical search index
donorSchema.index({ location: '2dsphere' })

const Donor = mongoose.model('Donor', donorSchema)

module.exports = Donor
