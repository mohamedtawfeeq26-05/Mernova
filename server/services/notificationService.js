const nodemailer = require('nodemailer')
const Notification = require('../models/Notification')
const User = require('../models/User')

let ioInstance = null

// Store Socket.io instance
const setIO = (io) => {
  ioInstance = io
}

const getIO = () => ioInstance

// ----------------------------------------------------
// 1. Nodemailer Email Configuration & Service
// ----------------------------------------------------
let mailTransporter = null

const initMailer = async () => {
  if (process.env.SMTP_HOST && process.env.SMTP_USER) {
    mailTransporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT || 587,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      }
    })
    console.log('✅ Nodemailer configured with Custom SMTP.')
  } else {
    // Generate ethereal test account or mock transporter for development
    try {
      const testAccount = await nodemailer.createTestAccount()
      mailTransporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass
        }
      })
      console.log('📧 Nodemailer running in Test/Ethereal mode:', testAccount.user)
    } catch (e) {
      console.log('ℹ️ Nodemailer local simulated mode active.')
    }
  }
}

initMailer()

const sendEmailAlert = async ({ to, subject, html, text }) => {
  try {
    if (!to) return
    const sender = process.env.EMAIL_FROM || '"BloodBridge Alert" <alerts@bloodbridge.org>'

    if (mailTransporter) {
      const info = await mailTransporter.sendMail({
        from: sender,
        to,
        subject,
        text: text || subject,
        html: html || `<p>${text || subject}</p>`
      })
      console.log(`✉️ Email alert sent to ${to} | ID: ${info.messageId}`)
      if (nodemailer.getTestMessageUrl(info)) {
        console.log(`🔗 Ethereal Email Preview: ${nodemailer.getTestMessageUrl(info)}`)
      }
      return { success: true, messageId: info.messageId }
    } else {
      console.log(`✉️ [Simulated Email] To: ${to} | Subject: ${subject}`)
      return { success: true, simulated: true }
    }
  } catch (error) {
    console.error(`❌ Failed to send email to ${to}:`, error.message)
    return { success: false, error: error.message }
  }
}

// ----------------------------------------------------
// 2. SMS API Service (Twilio / Gateway / Simulated API)
// ----------------------------------------------------
const sendSmsAlert = async ({ to, message }) => {
  try {
    if (!to) return

    // If Twilio credentials exist in env
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) {
      // Lazy load twilio only if configured
      const twilio = require('twilio')(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN)
      const res = await twilio.messages.create({
        body: message,
        from: process.env.TWILIO_PHONE_NUMBER,
        to
      })
      console.log(`📱 Twilio SMS delivered to ${to} | SID: ${res.sid}`)
      return { success: true, sid: res.sid }
    }

    // High fidelity SMS Gateway simulator log (standard for dev / demonstration)
    console.log(`📱 [SMS Gateway API] To: ${to} | Message: "${message}"`)
    return { success: true, simulated: true }
  } catch (error) {
    console.error(`❌ Failed to send SMS to ${to}:`, error.message)
    return { success: false, error: error.message }
  }
}

// ----------------------------------------------------
// 3. Blood Group Compatibility Helper
// ----------------------------------------------------
const getCompatibleDonorGroups = (recipientGroup) => {
  // Blood compatibility chart for receiving
  const compatibilityMap = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], // Universal recipient
    'AB-': ['AB-', 'A-', 'B-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'] // Only O-
  }
  return compatibilityMap[recipientGroup] || [recipientGroup]
}

// ----------------------------------------------------
// 4. Notify Matching Donors on Blood Request Creation
// ----------------------------------------------------
const notifyMatchingDonors = async (bloodRequest) => {
  try {
    const io = getIO()
    const compatibleGroups = getCompatibleDonorGroups(bloodRequest.bloodGroup)

    // Find all matching eligible available donors
    const filter = {
      role: 'donor',
      bloodGroup: { $in: compatibleGroups },
      availability: 'Available'
    }

    const matchingDonors = await User.find(filter)

    console.log(`🔔 Found ${matchingDonors.length} matching available donors for request [${bloodRequest.bloodGroup} in ${bloodRequest.city}]`)

    const isEmergency = bloodRequest.urgency === 'Emergency' || bloodRequest.urgency === 'Critical'
    const alertType = isEmergency ? 'EMERGENCY_ALERT' : 'REQUEST_MATCH'
    const title = isEmergency
      ? `🚨 EMERGENCY: ${bloodRequest.bloodGroup} Blood Needed Urgently!`
      : `🩸 Matching Blood Request: ${bloodRequest.bloodGroup} in ${bloodRequest.city}`

    const description = `Patient ${bloodRequest.patientName} at ${bloodRequest.hospitalName}, ${bloodRequest.city} requires ${bloodRequest.unitsRequired} unit(s) of ${bloodRequest.bloodGroup} blood.`

    // Send notifications to each matching donor
    for (const donor of matchingDonors) {
      // 1. Create In-App Notification document
      const notification = await Notification.create({
        recipient: donor._id,
        type: alertType,
        title,
        message: description,
        bloodRequest: bloodRequest._id,
        metadata: {
          urgency: bloodRequest.urgency,
          hospital: bloodRequest.hospitalName,
          city: bloodRequest.city,
          bloodGroup: bloodRequest.bloodGroup
        }
      })

      // 2. Real-Time Socket.IO event to donor's room
      if (io) {
        io.to(`user_${donor._id}`).emit('new_notification', {
          notification,
          bloodRequest
        })
      }

      // 3. Email Alert via Nodemailer
      const emailHtml = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
          <h2 style="color: ${isEmergency ? '#dc2626' : '#b91c1c'}; margin-top: 0;">${title}</h2>
          <p>Dear <strong>${donor.name}</strong>,</p>
          <p>A new blood request matches your blood group <strong>(${donor.bloodGroup})</strong> and location:</p>
          <div style="background-color: #fef2f2; padding: 15px; border-left: 4px solid #ef4444; margin: 15px 0;">
            <p style="margin: 4px 0;"><strong>Patient:</strong> ${bloodRequest.patientName}</p>
            <p style="margin: 4px 0;"><strong>Blood Group:</strong> ${bloodRequest.bloodGroup}</p>
            <p style="margin: 4px 0;"><strong>Units Needed:</strong> ${bloodRequest.unitsRequired}</p>
            <p style="margin: 4px 0;"><strong>Hospital:</strong> ${bloodRequest.hospitalName}, ${bloodRequest.city}</p>
            <p style="margin: 4px 0;"><strong>Contact:</strong> ${bloodRequest.contactPhone}</p>
            <p style="margin: 4px 0;"><strong>Urgency:</strong> <span style="color: red; font-weight: bold;">${bloodRequest.urgency}</span></p>
          </div>
          <p>If you are available to donate, please log in to BloodBridge to accept this request and save a life.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
          <p style="font-size: 12px; color: #888;">BloodBridge Real-Time Donor Network</p>
        </div>
      `

      sendEmailAlert({
        to: donor.email,
        subject: title,
        html: emailHtml,
        text: `${title}\n${description}\nHospital: ${bloodRequest.hospitalName}, ${bloodRequest.city}\nPhone: ${bloodRequest.contactPhone}`
      })

      // 4. SMS Alert
      const smsMessage = `[BloodBridge Alert] ${title}. ${bloodRequest.unitsRequired} unit(s) of ${bloodRequest.bloodGroup} needed at ${bloodRequest.hospitalName}, ${bloodRequest.city}. Contact: ${bloodRequest.contactPhone}`
      sendSmsAlert({
        to: donor.phone,
        message: smsMessage
      })
    }

    // Broadcast Socket.IO event to bloodGroup broadcast channel
    if (io) {
      io.to(`blood_${bloodRequest.bloodGroup}`).emit('blood_request_created', {
        bloodRequest,
        urgency: bloodRequest.urgency
      })
      if (isEmergency) {
        io.emit('emergency_broadcast', {
          bloodRequest,
          message: `🚨 Emergency: ${bloodRequest.bloodGroup} blood required at ${bloodRequest.hospitalName}!`
        })
      }
    }
  } catch (error) {
    console.error('Error notifying matching donors:', error)
  }
}

// ----------------------------------------------------
// 5. Notify Requester When Request is Accepted
// ----------------------------------------------------
const notifyRequestAccepted = async ({ bloodRequest, donor }) => {
  try {
    const io = getIO()
    const requester = await User.findById(bloodRequest.requester)

    if (!requester) return

    const title = `✅ Blood Request Accepted by Donor!`
    const message = `Donor ${donor.name} (${donor.bloodGroup}) has accepted your request for patient ${bloodRequest.patientName}. Donor contact: ${donor.phone}.`

    // 1. In-app Notification
    const notification = await Notification.create({
      recipient: requester._id,
      type: 'REQUEST_ACCEPTED',
      title,
      message,
      bloodRequest: bloodRequest._id,
      metadata: {
        donorName: donor.name,
        donorPhone: donor.phone,
        donorBloodGroup: donor.bloodGroup,
        patientName: bloodRequest.patientName
      }
    })

    // 2. Real-time Socket.IO emit to requester
    if (io) {
      io.to(`user_${requester._id}`).emit('new_notification', {
        notification,
        bloodRequest,
        donor: {
          name: donor.name,
          phone: donor.phone,
          bloodGroup: donor.bloodGroup
        }
      })
      io.to(`user_${requester._id}`).emit('request_accepted', {
        bloodRequestId: bloodRequest._id,
        donor: {
          name: donor.name,
          phone: donor.phone,
          bloodGroup: donor.bloodGroup
        }
      })
    }

    // 3. Email Alert to Requester
    const emailHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #15803d; margin-top: 0;">Good News! Your Blood Request Was Accepted</h2>
        <p>Dear <strong>${requester.name}</strong>,</p>
        <p>A donor has answered your call for patient <strong>${bloodRequest.patientName}</strong>:</p>
        <div style="background-color: #f0fdf4; padding: 15px; border-left: 4px solid #22c55e; margin: 15px 0;">
          <p style="margin: 4px 0;"><strong>Donor Name:</strong> ${donor.name}</p>
          <p style="margin: 4px 0;"><strong>Donor Blood Group:</strong> ${donor.bloodGroup}</p>
          <p style="margin: 4px 0;"><strong>Donor Phone:</strong> <a href="tel:${donor.phone}">${donor.phone}</a></p>
          <p style="margin: 4px 0;"><strong>Hospital:</strong> ${bloodRequest.hospitalName}</p>
        </div>
        <p>Please contact the donor immediately to coordinate the donation.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
        <p style="font-size: 12px; color: #888;">BloodBridge Real-Time Alerts</p>
      </div>
    `

    sendEmailAlert({
      to: requester.email,
      subject: `BloodBridge: Request Accepted by Donor ${donor.name}`,
      html: emailHtml,
      text: `${title}\n${message}`
    })

    // 4. SMS Alert to Requester
    const smsMessage = `[BloodBridge] Great news! Donor ${donor.name} (${donor.bloodGroup}) accepted your blood request for ${bloodRequest.patientName}. Contact: ${donor.phone}.`
    sendSmsAlert({
      to: requester.phone,
      message: smsMessage
    })
  } catch (error) {
    console.error('Error notifying requester of acceptance:', error)
  }
}

// ----------------------------------------------------
// 6. Automatic Availability Reminders
// ----------------------------------------------------
const checkAndSendAvailabilityReminders = async () => {
  try {
    const io = getIO()
    const now = new Date()

    // Find donors who have a nextEligibleDate that has passed,
    // and either haven't received a reminder in the last 7 days or are currently marked Unavailable
    const donors = await User.find({
      role: 'donor',
      nextEligibleDate: { $lte: now },
      $or: [
        { availability: 'Unavailable' },
        { lastReminderSentAt: { $exists: false } },
        { lastReminderSentAt: { $lt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) } }
      ]
    })

    console.log(`⏰ Checking eligibility reminders: ${donors.length} donors are eligible again.`)

    for (const donor of donors) {
      // Auto update availability to Available if they were cool-down locked
      donor.availability = 'Available'
      donor.lastReminderSentAt = now
      await donor.save()

      const title = '🩸 You Are Now Eligible to Donate Blood Again!'
      const message = `Hello ${donor.name}, your mandatory recovery period since your last donation has ended. Your availability has been updated to 'Available'. Thank you for being a hero!`

      // Save notification
      const notification = await Notification.create({
        recipient: donor._id,
        type: 'AVAILABILITY_REMINDER',
        title,
        message,
        metadata: {
          lastDonationDate: donor.lastDonationDate,
          nextEligibleDate: donor.nextEligibleDate
        }
      })

      // Realtime notification
      if (io) {
        io.to(`user_${donor._id}`).emit('new_notification', { notification })
        io.to(`user_${donor._id}`).emit('availability_updated', {
          availability: 'Available',
          message: 'You are now eligible to donate blood again!'
        })
      }

      // Email reminder
      sendEmailAlert({
        to: donor.email,
        subject: title,
        text: message,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #dc2626;">${title}</h2>
            <p>Dear <strong>${donor.name}</strong>,</p>
            <p>${message}</p>
            <p>Patients in need of <strong>${donor.bloodGroup}</strong> blood rely on donors like you. Your status is now marked as <strong>Available</strong>.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
            <p style="font-size: 12px; color: #888;">BloodBridge Availability System</p>
          </div>
        `
      })

      // SMS reminder
      sendSmsAlert({
        to: donor.phone,
        message: `[BloodBridge] Hi ${donor.name}, your donation recovery period is complete! You are now eligible to donate blood again. Thank you for saving lives!`
      })
    }

    return { processedCount: donors.length }
  } catch (error) {
    console.error('Error running availability reminders:', error)
    return { error: error.message }
  }
}

module.exports = {
  setIO,
  getIO,
  sendEmailAlert,
  sendSmsAlert,
  notifyMatchingDonors,
  notifyRequestAccepted,
  checkAndSendAvailabilityReminders,
  getCompatibleDonorGroups
}
