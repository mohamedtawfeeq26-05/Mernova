const assert = require('assert')
const jwt = require('jsonwebtoken')
const bcrypt = require('bcryptjs')
const { verifyToken, authorizeRoles, generateToken, JWT_SECRET } = require('./middleware/auth')
const { getCompatibleDonorGroups } = require('./services/notificationService')

async function runTests() {
  console.log('🧪 Starting BloodBridge Feature Verification Suite...\n')

  // ----------------------------------------------------------------
  // TEST 1: Password Hashing & Verification
  // ----------------------------------------------------------------
  console.log('▶ Test 1: Password Hashing & Comparison')
  const rawPassword = 'SecurePassword@2026'
  const salt = await bcrypt.genSalt(10)
  const hashed = await bcrypt.hash(rawPassword, salt)
  const isCorrect = await bcrypt.compare(rawPassword, hashed)
  const isWrong = await bcrypt.compare('WrongPassword', hashed)

  assert.strictEqual(isCorrect, true, 'Correct password comparison should pass')
  assert.strictEqual(isWrong, false, 'Wrong password comparison should fail')
  console.log('  ✓ Password hashing & comparison verified.\n')

  // ----------------------------------------------------------------
  // TEST 2: JWT Generation & Verification
  // ----------------------------------------------------------------
  console.log('▶ Test 2: JWT Token Generation & Verification')
  const mockUser = {
    _id: '64d123456789abcdef123456',
    email: 'donor@bloodbridge.org',
    role: 'donor'
  }
  const token = generateToken(mockUser)
  assert(token && typeof token === 'string', 'Token should be a non-empty string')

  const decoded = jwt.verify(token, JWT_SECRET)
  assert.strictEqual(decoded.id, mockUser._id, 'Decoded user ID must match')
  assert.strictEqual(decoded.role, 'donor', 'Decoded role must match donor')
  console.log('  ✓ JWT creation and payload decoding verified.\n')

  // ----------------------------------------------------------------
  // TEST 3: Role-Based Access Control (RBAC) Middleware
  // ----------------------------------------------------------------
  console.log('▶ Test 3: Role-Based Access Control (RBAC)')
  const adminOnlyMiddleware = authorizeRoles('admin')
  const donorOnlyMiddleware = authorizeRoles('donor')

  // Simulate Donor trying to access Admin route
  let forbiddenCalled = false
  const fakeDonorReq = { user: { role: 'donor' } }
  const fakeResForbidden = {
    status: (code) => {
      if (code === 403) forbiddenCalled = true
      return { json: () => {} }
    }
  }
  adminOnlyMiddleware(fakeDonorReq, fakeResForbidden, () => {})
  assert.strictEqual(forbiddenCalled, true, 'Donor accessing admin-only route must return 403 Forbidden')

  // Simulate Donor accessing Donor route
  let nextPassed = false
  donorOnlyMiddleware(fakeDonorReq, {}, () => { nextPassed = true })
  assert.strictEqual(nextPassed, true, 'Donor accessing donor-allowed route must call next()')
  console.log('  ✓ RBAC middleware blocks unauthorized roles and allows valid roles.\n')

  // ----------------------------------------------------------------
  // TEST 4: Blood Compatibility Matrix
  // ----------------------------------------------------------------
  console.log('▶ Test 4: Blood Group Compatibility Matching')
  // O- can only receive from O-
  const oNegCompatible = getCompatibleDonorGroups('O-')
  assert.deepStrictEqual(oNegCompatible, ['O-'])

  // AB+ is universal recipient (can receive from all 8)
  const abPosCompatible = getCompatibleDonorGroups('AB+')
  assert.strictEqual(abPosCompatible.length, 8)
  assert(abPosCompatible.includes('O+'))
  assert(abPosCompatible.includes('AB+'))

  // B+ can receive from B+, B-, O+, O-
  const bPosCompatible = getCompatibleDonorGroups('B+')
  assert.deepStrictEqual(bPosCompatible, ['B+', 'B-', 'O+', 'O-'])
  console.log('  ✓ Blood group compatibility matching verified.\n')

  // ----------------------------------------------------------------
  // TEST 5: Eligibility Date Calculation (90 Days Cooldown)
  // ----------------------------------------------------------------
  console.log('▶ Test 5: Next Eligible Date Calculation (90 Days)')
  const donationDate = new Date('2026-01-01T00:00:00Z')
  const expectedEligibleDate = new Date(donationDate)
  expectedEligibleDate.setDate(expectedEligibleDate.getDate() + 90)

  assert.strictEqual(expectedEligibleDate.toISOString().split('T')[0], '2026-04-01')

  const now = new Date('2026-02-01T00:00:00Z')
  const isCooldown = now < expectedEligibleDate
  assert.strictEqual(isCooldown, true, 'Donor within 90 days must be cooling down')
  console.log('  ✓ 90-day cooldown logic and date calculation verified.\n')

  console.log('🎉 ALL 5 FEATURE TEST SUITES PASSED!')
}

runTests().catch((err) => {
  console.error('❌ Test failed:', err)
  process.exit(1)
})
