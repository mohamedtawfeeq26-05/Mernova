const mongoose = require('mongoose')
const bcrypt = require('bcryptjs')
require('dotenv').config()

const User = require('./models/User')
const BloodRequest = require('./models/BloodRequest')
const Notification = require('./models/Notification')
const Donor = require('./models/Donor')

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/BloodBridge'

async function seedDatabase() {
  try {
    console.log('🩸 Connecting to MongoDB for professional database seeding...')
    await mongoose.connect(MONGO_URI)
    console.log('✅ Connected to MongoDB.')

    // Clear existing collections for a clean, consistent presentation
    console.log('🧹 Clearing old collections...')
    await User.deleteMany({})
    await BloodRequest.deleteMany({})
    await Notification.deleteMany({})
    await Donor.deleteMany({})

    console.log('🌱 Generating professional seed data...')

    // 1. Password hash
    const defaultPassword = 'Password@123'
    const adminPassword = 'AdminPassword@123'
    const salt = await bcrypt.genSalt(10)
    const hashedUserPass = await bcrypt.hash(defaultPassword, salt)
    const hashedAdminPass = await bcrypt.hash(adminPassword, salt)

    const now = new Date()

    // 2. Create Users
    // --- ADMIN ---
    const adminUser = await User.create({
      name: 'System Administrator',
      email: 'admin@bloodbridge.org',
      password: hashedAdminPass,
      phone: '9876543200',
      role: 'admin',
      city: 'Mumbai',
      address: 'Central Health Directorate'
    })

    // --- REQUESTERS (Hospitals & Relatives) ---
    const requester1 = await User.create({
      name: 'Dr. Rajesh Sharma (Apollo Hospital)',
      email: 'apollo.mumbai@bloodbridge.org',
      password: hashedUserPass,
      phone: '9820011223',
      role: 'requester',
      city: 'Mumbai',
      address: 'Apollo Hospitals, Sector 23, Belapur'
    })

    const requester2 = await User.create({
      name: 'Priya Verma (Patient Relative)',
      email: 'priya.verma@example.com',
      password: hashedUserPass,
      phone: '9811223344',
      role: 'requester',
      city: 'Delhi',
      address: 'AIIMS Trauma Center, Ansari Nagar'
    })

    // --- DONORS (Varied Blood Groups, Eligibility & Availability) ---
    // Donor 1: O+ Available (Ideal for universal positive matching)
    const donor1 = await User.create({
      name: 'Rahul Deshmukh',
      email: 'rahul.donor@bloodbridge.org',
      password: hashedUserPass,
      phone: '9876500001',
      role: 'donor',
      bloodGroup: 'O+',
      age: 28,
      gender: 'Male',
      city: 'Mumbai',
      address: 'Bandra West',
      pincode: '400050',
      availability: 'Available',
      totalDonations: 4,
      lastDonationDate: new Date(now.getTime() - 110 * 24 * 60 * 60 * 1000), // 110 days ago (Eligible)
      nextEligibleDate: new Date(now.getTime() - 20 * 24 * 60 * 60 * 1000)
    })

    // Donor 2: A+ Available
    const donor2 = await User.create({
      name: 'Ananya Iyer',
      email: 'ananya.donor@bloodbridge.org',
      password: hashedUserPass,
      phone: '9876500002',
      role: 'donor',
      bloodGroup: 'A+',
      age: 24,
      gender: 'Female',
      city: 'Mumbai',
      address: 'Powai Lake Road',
      pincode: '400076',
      availability: 'Available',
      totalDonations: 2,
      lastDonationDate: new Date(now.getTime() - 95 * 24 * 60 * 60 * 1000),
      nextEligibleDate: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000)
    })

    // Donor 3: O- Rare Universal Donor (Unavailable - In 90-day recovery cooldown)
    const donor3 = await User.create({
      name: 'Vikramaditya Roy',
      email: 'vikram.donor@bloodbridge.org',
      password: hashedUserPass,
      phone: '9876500003',
      role: 'donor',
      bloodGroup: 'O-',
      age: 32,
      gender: 'Male',
      city: 'Delhi',
      address: 'Hauz Khas Enclave',
      pincode: '110016',
      availability: 'Unavailable',
      totalDonations: 7,
      lastDonationDate: new Date(now.getTime() - 40 * 24 * 60 * 60 * 1000), // 40 days ago
      nextEligibleDate: new Date(now.getTime() + 50 * 24 * 60 * 60 * 1000) // 50 days remaining
    })

    // Donor 4: B+ Available
    const donor4 = await User.create({
      name: 'Sneha Kulkarni',
      email: 'sneha.donor@bloodbridge.org',
      password: hashedUserPass,
      phone: '9876500004',
      role: 'donor',
      bloodGroup: 'B+',
      age: 26,
      gender: 'Female',
      city: 'Pune',
      address: 'Kothrud',
      pincode: '411038',
      availability: 'Available',
      totalDonations: 3,
      lastDonationDate: new Date(now.getTime() - 120 * 24 * 60 * 60 * 1000),
      nextEligibleDate: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
    })

    // Donor 5: AB+ Available (Universal Recipient)
    const donor5 = await User.create({
      name: 'Arjun Mehta',
      email: 'arjun.donor@bloodbridge.org',
      password: hashedUserPass,
      phone: '9876500005',
      role: 'donor',
      bloodGroup: 'AB+',
      age: 29,
      gender: 'Male',
      city: 'Mumbai',
      address: 'Andheri East',
      pincode: '400069',
      availability: 'Available',
      totalDonations: 1
    })

    console.log('✅ Created 8 realistic User accounts (1 Admin, 2 Requesters, 5 Donors).')

    // 3. Create Blood Requests
    // Request 1: Critical Emergency (Pending matching)
    const request1 = await BloodRequest.create({
      requester: requester1._id,
      patientName: 'Aarav Patel (Age 34)',
      hospitalName: 'Apollo Speciality Hospital',
      bloodGroup: 'O+',
      unitsRequired: 2,
      urgency: 'Emergency',
      city: 'Mumbai',
      address: 'ICU Ward 3, Apollo Hospitals, Belapur',
      contactPhone: '9820011223',
      notes: 'Emergency bypass surgery scheduled. Platelets and whole blood urgently required.',
      status: 'Pending'
    })

    // Request 2: Normal request (Pending)
    const request2 = await BloodRequest.create({
      requester: requester2._id,
      patientName: 'Kavita Verma (Age 52)',
      hospitalName: 'AIIMS Hospital',
      bloodGroup: 'B+',
      unitsRequired: 1,
      urgency: 'Normal',
      city: 'Delhi',
      address: 'Hematology Ward 2, Room 204',
      contactPhone: '9811223344',
      notes: 'Thalassemia scheduled transfusion.',
      status: 'Pending'
    })

    // Request 3: Accepted Emergency Request (Accepted by Donor Rahul Deshmukh)
    const request3 = await BloodRequest.create({
      requester: requester1._id,
      patientName: 'Sunita Rao (Age 42)',
      hospitalName: 'Lilavati Hospital & Research Centre',
      bloodGroup: 'O+',
      unitsRequired: 2,
      urgency: 'Emergency',
      city: 'Mumbai',
      address: 'Critical Care Wing, Lilavati Bandra',
      contactPhone: '9820011223',
      notes: 'Post-accident trauma resuscitation.',
      status: 'Accepted',
      acceptedBy: donor1._id,
      acceptedAt: new Date(now.getTime() - 2 * 60 * 60 * 1000)
    })

    // Request 4: Fulfilled Request (Saved Life)
    await BloodRequest.create({
      requester: requester2._id,
      patientName: 'Rohan Gupta (Age 19)',
      hospitalName: 'Fortis Memorial Research Institute',
      bloodGroup: 'A+',
      unitsRequired: 1,
      urgency: 'Emergency',
      city: 'Delhi',
      address: 'Emergency Trauma Ward',
      contactPhone: '9811223344',
      notes: 'Donation fulfilled successfully yesterday.',
      status: 'Fulfilled',
      acceptedBy: donor2._id,
      acceptedAt: new Date(now.getTime() - 24 * 60 * 60 * 1000)
    })

    console.log('✅ Created 4 representative Blood Requests (Pending, Accepted, Fulfilled).')

    // 4. Create Notifications
    await Notification.create([
      {
        recipient: donor1._id,
        type: 'EMERGENCY_ALERT',
        title: '🚨 EMERGENCY: O+ Blood Needed Urgently!',
        message: 'Patient Aarav Patel at Apollo Speciality Hospital requires 2 unit(s) of O+ blood.',
        bloodRequest: request1._id,
        read: false
      },
      {
        recipient: requester1._id,
        type: 'REQUEST_ACCEPTED',
        title: '✅ Blood Request Accepted by Donor!',
        message: 'Donor Rahul Deshmukh (O+) has accepted your request for patient Sunita Rao.',
        bloodRequest: request3._id,
        read: true
      },
      {
        recipient: donor3._id,
        type: 'AVAILABILITY_REMINDER',
        title: '⏰ Donation Recovery Cooldown in Effect',
        message: 'You have 50 days remaining before your next eligible donation. Thank you for being a hero!',
        read: true
      }
    ])

    console.log('✅ Created sample notifications.')

    console.log('\n======================================================')
    console.log('🎉 PROFESSIONAL DATABASE SEEDING COMPLETED SUCCESSFULLY')
    console.log('======================================================')
    console.log('\n📋 TEACHER PRESENTATION TEST ACCOUNTS:\n')
    console.log('1. ADMINISTRATOR PORTAL:')
    console.log('   Email:    admin@bloodbridge.org')
    console.log('   Password: AdminPassword@123')
    console.log('   Role:     admin (Metrics, RBAC User list, Emergency status)\n')
    console.log('2. BLOOD DONOR ACCOUNT (Eligible & Available):')
    console.log('   Email:    rahul.donor@bloodbridge.org')
    console.log('   Password: Password@123')
    console.log('   Blood:    O+ | Can accept emergency requests & manage availability\n')
    console.log('3. BLOOD DONOR ACCOUNT (In 90-Day Cooldown):')
    console.log('   Email:    vikram.donor@bloodbridge.org')
    console.log('   Password: Password@123')
    console.log('   Blood:    O- | Shows active cooldown & automated reminder logic\n')
    console.log('4. PATIENT / REQUESTER ACCOUNT (Hospital):')
    console.log('   Email:    apollo.mumbai@bloodbridge.org')
    console.log('   Password: Password@123')
    console.log('   Role:     requester (Can post emergency requests & receive live alerts)\n')
    console.log('======================================================\n')

    process.exit(0)
  } catch (error) {
    console.error('❌ Seeding error:', error)
    process.exit(1)
  }
}

seedDatabase()
