
import { useState } from 'react'
import { useAuth } from './AuthContext'
import { API_URL } from './config'
import './AuthModal.css'

export default function AuthModal({
  isOpen,
  onClose,
  initialMode = 'login',
  initialRole = 'donor'
}) {
  const { login } = useAuth()

  const [isLogin, setIsLogin] = useState(initialMode === 'login')
  const [role, setRole] = useState(initialRole)

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    phone: '',
    bloodGroup: 'O+',
    age: '25',
    gender: 'Male',
    city: '',
    address: '',
    pincode: ''
  })

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  if (!isOpen) return null

  // Handle input changes
  const handleChange = (e) => {
    const { name, value } = e.target

    setFormData((prev) => ({
      ...prev,
      [name]: value
    }))

    setError('')
  }

  // Mobile number validation
  const validatePhone = (phone) => {
    const phoneRegex = /^[6-9][0-9]{9}$/
    return phoneRegex.test(phone)
  }

  // Password validation
  const validatePassword = (password) => {
    const passwordRegex =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$/

    return passwordRegex.test(password)
  }

  // Quick-fill demo credentials
  const fillPreset = (presetRole, email, pass) => {
    setIsLogin(true)
    setRole(presetRole)

    setFormData((prev) => ({
      ...prev,
      email,
      password: pass
    }))

    setError('')
    setSuccess('')
  }

  // Handle login and registration
  const handleSubmit = async (e) => {
    e.preventDefault()

    setError('')
    setSuccess('')

    // Registration validations
    if (!isLogin) {

      if (!formData.name.trim()) {
        setError('Please enter your full name.')
        return
      }

      if (!validatePhone(formData.phone)) {
        setError(
          'Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8 or 9.'
        )
        return
      }

      if (!validatePassword(formData.password)) {
        setError(
          'Password must contain at least 8 characters, one uppercase letter, one lowercase letter, one number and one special character.'
        )
        return
      }
    }

    setLoading(true)

    const endpoint = isLogin
      ? '/api/auth/login'
      : '/api/auth/register'

    try {
      const payload = isLogin
        ? {
            email: formData.email,
            password: formData.password,
            role
          }
        : {
            ...formData,
            name: formData.name.trim(),
            phone: formData.phone,
            role,
            age: Number(formData.age) || undefined
          }

          

      const res = await fetch(`${API_URL}${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      })

      const data = await res.json()

      if (!res.ok) {
        throw new Error(data.message || 'Authentication failed')
      }

      login(data.user, data.token)

      setSuccess(
        `Welcome, ${data.user.name}! Logged in as ${data.user.role}.`
      )

      setTimeout(() => {
        onClose()
      }, 800)

    } catch (err) {
      setError(err.message || 'Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="modal-backdrop">
      <div className="auth-modal">

        <button
          className="modal-close"
          type="button"
          onClick={onClose}
        >
          ✕
        </button>

        {/* HEADER */}
        <div className="auth-header">
          <h2>🩸 BloodBridge Access</h2>
          <p>Login or Register with Role-Based Access Control</p>
        </div>

        {/* DEMO LOGIN PRESETS */}
        <div className="evaluation-presets">
          <span className="preset-label">
            ⚡ One-Click Evaluation Login:
          </span>

          <div className="preset-buttons">

            <button
              type="button"
              className="btn-preset admin"
              onClick={() =>
                fillPreset(
                  'admin',
                  'admin@bloodbridge.org',
                  'AdminPassword@123'
                )
              }
            >
              🛡️ Admin
            </button>

            <button
              type="button"
              className="btn-preset donor"
              onClick={() =>
                fillPreset(
                  'donor',
                  'rahul.donor@bloodbridge.org',
                  'Password@123'
                )
              }
            >
              🩸 Donor (O+)
            </button>

            <button
              type="button"
              className="btn-preset requester"
              onClick={() =>
                fillPreset(
                  'requester',
                  'apollo.mumbai@bloodbridge.org',
                  'Password@123'
                )
              }
            >
              🏥 Hospital
            </button>

          </div>
        </div>

        {/* LOGIN / REGISTER TABS */}
        <div className="auth-tabs">

          <button
            type="button"
            className={`tab-btn ${isLogin ? 'active' : ''}`}
            onClick={() => {
              setIsLogin(true)
              setError('')
              setSuccess('')
            }}
          >
            Sign In
          </button>

          <button
            type="button"
            className={`tab-btn ${!isLogin ? 'active' : ''}`}
            onClick={() => {
              setIsLogin(false)
              setError('')
              setSuccess('')
            }}
          >
            Create Account
          </button>

        </div>

        {/* ROLE SELECTOR */}
        <div className="role-selector-container">

          <label>Selected Role:</label>

          <div className="role-pills">

            <button
              type="button"
              className={`role-pill ${role === 'donor' ? 'active-donor' : ''}`}
              onClick={() => {
                setRole('donor')
                setError('')
              }}
            >
              🩸 Blood Donor
            </button>

            <button
              type="button"
              className={`role-pill ${role === 'requester' ? 'active-requester' : ''}`}
              onClick={() => {
                setRole('requester')
                setError('')
              }}
            >
              🏥 Patient / Requester
            </button>

            <button
              type="button"
              className={`role-pill ${role === 'admin' ? 'active-admin' : ''}`}
              onClick={() => {
                setRole('admin')
                setError('')
              }}
            >
              🛡️ Administrator
            </button>

          </div>
        </div>

        {/* AUTHENTICATION FORM */}
        <form
          onSubmit={handleSubmit}
          className="auth-form"
        >

          {/* FULL NAME */}
          {!isLogin && (
            <div className="form-group">

              <label>Full Name</label>

              <input
                type="text"
                name="name"
                required
                placeholder="Enter full name"
                value={formData.name}
                onChange={handleChange}
              />

            </div>
          )}

          {/* EMAIL */}
          <div className="form-group">

            <label>Email Address</label>

            <input
              type="email"
              name="email"
              required
              placeholder="name@example.com"
              value={formData.email}
              onChange={handleChange}
            />

          </div>

          {/* PASSWORD */}
          <div className="form-group">

            <label>Password</label>

            <input
              type="password"
              name="password"
              required
              placeholder="Enter your password"
              value={formData.password}
              onChange={handleChange}
              minLength={!isLogin ? 8 : undefined}
              autoComplete={
                isLogin ? 'current-password' : 'new-password'
              }
            />

            {!isLogin && (
              <small className="password-hint">
                Password requirements:
                <br />
                • Minimum 8 characters
                <br />
                • At least one uppercase letter (A-Z)
                <br />
                • At least one lowercase letter (a-z)
                <br />
                • At least one number (0-9)
                <br />
                • At least one special character (@$!%*?&#)
              </small>
            )}

          </div>

          {/* REGISTRATION FIELDS */}
          {!isLogin && (
            <>

              {/* MOBILE NUMBER */}
              <div className="form-group">

                <label>Mobile Number (For SMS Alerts)</label>

                <input
                  type="tel"
                  name="phone"
                  required
                  placeholder="Enter 10-digit mobile number"
                  value={formData.phone}
                  onChange={(e) => {
                    const value = e.target.value
                      .replace(/\D/g, '')
                      .slice(0, 10)

                    setFormData((prev) => ({
                      ...prev,
                      phone: value
                    }))

                    setError('')
                  }}
                  pattern="[6-9][0-9]{9}"
                  minLength={10}
                  maxLength={10}
                  inputMode="numeric"
                  title="Enter a valid 10-digit Indian mobile number starting with 6, 7, 8 or 9"
                />

                <small className="password-hint">
                  Enter exactly 10 digits. The number must start with
                  6, 7, 8 or 9.
                </small>

              </div>

              {/* DONOR DETAILS */}
              {role === 'donor' && (
                <div className="form-row">

                  <div className="form-group">

                    <label>Blood Group</label>

                    <select
                      name="bloodGroup"
                      value={formData.bloodGroup}
                      onChange={handleChange}
                      required
                    >
                      <option value="A+">A+</option>
                      <option value="A-">A-</option>
                      <option value="B+">B+</option>
                      <option value="B-">B-</option>
                      <option value="AB+">AB+</option>
                      <option value="AB-">AB-</option>
                      <option value="O+">O+</option>
                      <option value="O-">O-</option>
                    </select>

                  </div>

                  <div className="form-group">

                    <label>Age</label>

                    <input
                      type="number"
                      name="age"
                      min="18"
                      max="75"
                      value={formData.age}
                      onChange={handleChange}
                      required
                    />

                  </div>

                </div>
              )}

              {/* CITY AND PINCODE */}
              <div className="form-row">

                <div className="form-group">

                  <label>City</label>

                  <input
                    type="text"
                    name="city"
                    placeholder="Enter city"
                    value={formData.city}
                    onChange={handleChange}
                    required
                  />

                </div>

                <div className="form-group">

                  <label>PIN Code</label>

                  <input
                    type="text"
                    name="pincode"
                    placeholder="PIN Code"
                    value={formData.pincode}
                    onChange={handleChange}
                  />

                </div>

              </div>

              {/* ADDRESS */}
              <div className="form-group">

                <label>Address / Hospital Vicinity</label>

                <input
                  type="text"
                  name="address"
                  placeholder="Street / locality"
                  value={formData.address}
                  onChange={handleChange}
                />

              </div>

            </>
          )}

          {/* ERROR MESSAGE */}
          {error && (
            <div className="auth-alert alert-error">
              {error}
            </div>
          )}

          {/* SUCCESS MESSAGE */}
          {success && (
            <div className="auth-alert alert-success">
              {success}
            </div>
          )}

          {/* SUBMIT BUTTON */}
          <button
            type="submit"
            className="btn-auth-submit"
            disabled={loading}
          >
            {loading
              ? 'Please wait...'
              : isLogin
                ? `Sign In as ${role}`
                : `Register as ${role}`}
          </button>

        </form>

      </div>
    </div>
  )
}
