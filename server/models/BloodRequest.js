const mongoose = require('mongoose')

const bloodRequestSchema = new mongoose.Schema(
  {
    requester: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    patientName: {
      type: String,
      required: true,
      trim: true
    },
    hospitalName: {
      type: String,
      required: true,
      trim: true
    },
    bloodGroup: {
      type: String,
      required: true,
      enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
    },
    unitsRequired: {
      type: Number,
      required: true,
      min: 1,
      default: 1
    },
    urgency: {
      type: String,
      enum: ['Normal', 'Emergency', 'Critical'],
      default: 'Normal'
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
    contactPhone: {
      type: String,
      required: true
    },
    notes: {
      type: String
    },
    status: {
      type: String,
      enum: ['Pending', 'Accepted', 'Fulfilled', 'Cancelled'],
      default: 'Pending'
    },
    acceptedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    acceptedAt: {
      type: Date
    }
  },
  { timestamps: true }
)

bloodRequestSchema.index({ bloodGroup: 1, city: 1, status: 1, urgency: 1 })

const BloodRequest = mongoose.model('BloodRequest', bloodRequestSchema)

module.exports = BloodRequest
