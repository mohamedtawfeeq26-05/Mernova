
import { useState } from 'react'
import { API_URL } from './config'
import './Register.css'

function Register() {

  const [formData, setFormData] = useState({
    name: '',
    age: '',
    gender: '',
    bloodGroup: '',
    phone: '',
    email: '',
    city: '',
    address: '',
    pincode: '',
    latitude: '',
    longitude: ''
  })

  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [locationLoading, setLocationLoading] = useState(false)

  // HANDLE INPUT CHANGES
  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
  }

  // CAPTURE GPS LOCATION
  const getDonorLocation = () => {

    if (!navigator.geolocation) {
      setMessage('GPS is not supported by your browser.')
      setMessageType('error')
      return
    }

    setLocationLoading(true)
    setMessage('')

    navigator.geolocation.getCurrentPosition(

      (position) => {

        setFormData((prev) => ({
          ...prev,
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        }))

        setMessage('Location captured successfully!')
        setMessageType('success')
        setLocationLoading(false)
      },

      (error) => {

        console.error('Location Error:', error.message)

        setMessage(
          'Unable to access location. Please allow location permission or continue without GPS.'
        )

        setMessageType('error')
        setLocationLoading(false)
      },

      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  }

  // REGISTER DONOR
  const handleSubmit = async (e) => {

    e.preventDefault()

    setMessage('')
    setIsSubmitting(true)

    try {

      const response = await fetch(
        `${API_URL}/api/donors/register`,
        {
          method: 'POST',

          headers: {
            'Content-Type': 'application/json'
          },

          body: JSON.stringify({
            ...formData,
            age: Number(formData.age),
            location:
              formData.latitude !== '' &&
              formData.longitude !== ''
                ? {
                    type: 'Point',
                    coordinates: [
                      Number(formData.longitude),
                      Number(formData.latitude)
                    ]
                  }
                : undefined
          })
        }
      )

      const data = await response.json()

      if (!response.ok) {
        throw new Error(
          data.error || data.message || 'Registration failed'
        )
      }

      setMessage(
        'Donor registered successfully! Your details have been saved.'
      )

      setMessageType('success')

      setFormData({
        name: '',
        age: '',
        gender: '',
        bloodGroup: '',
        phone: '',
        email: '',
        city: '',
        address: '',
        pincode: '',
        latitude: '',
        longitude: ''
      })

    } catch (error) {

      console.error('Registration Error:', error)

      setMessage(
        error.message || 'Unable to register. Please try again.'
      )

      setMessageType('error')

    } finally {

      setIsSubmitting(false)

    }
  }

  return (

    <div className="register-page">

      <div className="register-card">

        <h1>🩸 BloodBridge</h1>

        <h2>Donor Registration</h2>

        <p className="register-subtitle">
          Become a donor and help save lives.
        </p>

        <form onSubmit={handleSubmit}>

          <label>Full Name</label>

          <input
            type="text"
            name="name"
            placeholder="Enter your full name"
            value={formData.name}
            onChange={handleChange}
            required
          />

          <div className="form-row">

            <div>
              <label>Age</label>

              <input
                type="number"
                name="age"
                placeholder="Enter age"
                min="18"
                max="120"
                value={formData.age}
                onChange={handleChange}
                required
              />
            </div>

            <div>
              <label>Gender</label>

              <select
                name="gender"
                value={formData.gender}
                onChange={handleChange}
                required
              >
                <option value="">Select gender</option>
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Other">Other</option>
                <option value="Prefer not to say">
                  Prefer not to say
                </option>
              </select>
            </div>

          </div>

          <label>Blood Group</label>

          <select
            name="bloodGroup"
            value={formData.bloodGroup}
            onChange={handleChange}
            required
          >
            <option value="">Select blood group</option>
            <option value="A+">A+</option>
            <option value="A-">A-</option>
            <option value="B+">B+</option>
            <option value="B-">B-</option>
            <option value="AB+">AB+</option>
            <option value="AB-">AB-</option>
            <option value="O+">O+</option>
            <option value="O-">O-</option>
          </select>

          <label>Mobile Number</label>

          <input
            type="tel"
            name="phone"
            placeholder="Enter 10-digit mobile number"
            pattern="[0-9]{10}"
            maxLength="10"
            value={formData.phone}
            onChange={handleChange}
            required
          />

          <label>Email Address</label>

          <input
            type="email"
            name="email"
            placeholder="Enter your email"
            value={formData.email}
            onChange={handleChange}
            required
          />

          <label>City</label>

          <input
            type="text"
            name="city"
            placeholder="Enter your city"
            value={formData.city}
            onChange={handleChange}
            required
          />

          <label>PIN Code</label>

          <input
            type="text"
            name="pincode"
            placeholder="Enter 6-digit PIN code"
            pattern="[0-9]{6}"
            maxLength="6"
            value={formData.pincode}
            onChange={handleChange}
            required
          />

          <label>Address</label>

          <textarea
            name="address"
            placeholder="Enter your address"
            value={formData.address}
            onChange={handleChange}
            required
          />

          <div className="location-section">

            <label>GPS Location (Optional)</label>

            <p>
              Capture your location to help people find nearby donors.
            </p>

            <button
              type="button"
              onClick={getDonorLocation}
              disabled={locationLoading}
            >
              {locationLoading
                ? 'Capturing Location...'
                : '📍 Capture My Location'}
            </button>

            {formData.latitude !== '' &&
              formData.longitude !== '' && (

                <p className="location-success">
                  ✓ Location captured successfully!
                </p>

              )}

          </div>

          <button type="submit" disabled={isSubmitting}>
            {isSubmitting
              ? 'Registering...'
              : 'Register as Donor'}
          </button>

          {message && (
            <p
              className={
                messageType === 'success'
                  ? 'success-message'
                  : 'error-message'
              }
            >
              {message}
            </p>
          )}

        </form>

      </div>

    </div>

  )
}

export default Register
