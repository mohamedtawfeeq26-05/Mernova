import { useState, useEffect, useCallback, useMemo } from 'react'
import { useAuth } from './AuthContext'
import { API_URL } from './config'
import './DonorAvailability.css'

export default function DonorAvailability() {
  const { user, token, updateUser, isDonor } = useAuth()

  const [availability, setAvailability] = useState(user?.availability || 'Available')
  const [lastDonationDate, setLastDonationDate] = useState(
    user?.lastDonationDate ? new Date(user.lastDonationDate).toISOString().split('T')[0] : ''
  )
  const [nextEligibleDate, setNextEligibleDate] = useState(user?.nextEligibleDate || null)
  const [daysRemaining, setDaysRemaining] = useState(0)
  const [totalDonations, setTotalDonations] = useState(user?.totalDonations || 0)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState('')
  const [reminderLoading, setReminderLoading] = useState(false)

  const todayStr = useMemo(() => new Date().toISOString().split('T')[0], [])
  const isEligibleNow = useMemo(() => {
    return !nextEligibleDate || new Date(nextEligibleDate).getTime() <= Date.now()
  }, [nextEligibleDate])

  const fetchStatus = useCallback(async () => {
    if (!token || !isDonor) return
    try {
      const res = await fetch(`${API_URL}/api/donors/availability/me`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      const data = await res.json()
      if (data.success) {
        setAvailability(data.availability)
        setDaysRemaining(data.daysRemaining)
        setNextEligibleDate(data.nextEligibleDate)
        setTotalDonations(data.totalDonations)
        if (data.lastDonationDate) {
          setLastDonationDate(new Date(data.lastDonationDate).toISOString().split('T')[0])
        }
      }
    } catch (err) {
      console.error('Error fetching availability:', err)
    }
  }, [token, isDonor])

  useEffect(() => {
    fetchStatus()
  }, [fetchStatus])

  const handleToggle = async (newStatus) => {
    setLoading(true)
    setMessage('')
    try {
      const res = await fetch(`${API_URL}/api/donors/availability`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ availability: newStatus })
      })

      const data = await res.json()
      if (!res.ok) throw new Error(data.message || 'Failed to update')

      setAvailability(data.donor.availability)
      updateUser({ availability: data.donor.availability })
      setMessage(`Status updated to ${newStatus}!`)
      setMessageType('success')
    } catch (err) {
      setMessage(err.message)
      setMessageType('error')
    } finally {
      setLoading(false)
    }
  }

  const handleDateSubmit = async (e) => {
    e.preventDefault()
    if (!lastDonationDate) return

    setLoading(true)
    setMessage('')
    try {
      const res = await fetch(`${API_URL}/api/donors/availability`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          lastDonationDate,
          incrementDonationCount: true
        })
      })

      const data = await res.json()
      if (!res.ok) throw new Error(data.message || 'Failed to record donation')

      setAvailability(data.donor.availability)
      setNextEligibleDate(data.donor.nextEligibleDate)
      setTotalDonations(data.donor.totalDonations)
      updateUser(data.donor)

      if (data.donor.nextEligibleDate) {
        const diff = new Date(data.donor.nextEligibleDate) - new Date()
        setDaysRemaining(Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24))))
      }

      setMessage('Donation date recorded! 90-day recovery cooldown is active.')
      setMessageType('success')
    } catch (err) {
      setMessage(err.message)
      setMessageType('error')
    } finally {
      setLoading(false)
    }
  }

  const handleCheckReminders = async () => {
    setReminderLoading(true)
    try {
      const res = await fetch(`${API_URL}/api/donors/availability/reminders/trigger`, {
        method: 'POST'
      })
      const data = await res.json()
      setMessage(`Automated reminder check ran! ${data.result?.processedCount || 0} donors notified.`)
      setMessageType('success')
      fetchStatus()
    } catch {
      setMessage('Failed to run reminder check.')
      setMessageType('error')
    } finally {
      setReminderLoading(false)
    }
  }

  if (!isDonor) return null

  return (
    <div className="availability-card">
      <div className="card-header">
        <div>
          <h3>🩸 Donor Availability Management</h3>
          <p className="card-subtitle">Keep your donation status and eligibility up to date.</p>
        </div>
        <span className={`status-pill ${availability === 'Available' ? 'pill-available' : 'pill-unavailable'}`}>
          {availability === 'Available' ? '● Available to Donate' : '○ Unavailable'}
        </span>
      </div>

      <div className="metrics-grid">
        <div className="metric-box">
          <span className="metric-label">Current Status</span>
          <strong className={availability === 'Available' ? 'text-green' : 'text-red'}>
            {availability}
          </strong>
        </div>

        <div className="metric-box">
          <span className="metric-label">Next Eligible Date</span>
          <strong>
            {nextEligibleDate
              ? new Date(nextEligibleDate).toLocaleDateString('en-US', {
                  month: 'short',
                  day: 'numeric',
                  year: 'numeric'
                })
              : 'Eligible Now'}
          </strong>
        </div>

        <div className="metric-box">
          <span className="metric-label">Recovery Period</span>
          <strong className={daysRemaining > 0 ? 'text-amber' : 'text-green'}>
            {daysRemaining > 0 ? `${daysRemaining} days remaining` : 'Ready to Donate'}
          </strong>
        </div>

        <div className="metric-box">
          <span className="metric-label">Total Donations</span>
          <strong>{totalDonations} Times</strong>
        </div>
      </div>

      {daysRemaining > 0 && (
        <div className="cooldown-banner">
          <div className="cooldown-info">
            ⏳ <strong>Recovery Cooldown Active:</strong> Medical safety guidelines require 90 days
            between whole blood donations. Your status will automatically become eligible on{' '}
            <strong>{new Date(nextEligibleDate).toLocaleDateString()}</strong>.
          </div>
          <div className="cooldown-progress-container">
            <div className="cooldown-progress-bar">
              <div
                className="cooldown-progress-fill"
                style={{ width: `${Math.min(100, Math.max(5, Math.round(((90 - daysRemaining) / 90) * 100)))}%` }}
              />
            </div>
            <span className="cooldown-percent">
              {Math.min(100, Math.max(0, Math.round(((90 - daysRemaining) / 90) * 100)))}% Recovery Completed ({daysRemaining} days left)
            </span>
          </div>
        </div>
      )}

      <div className="availability-actions">
        <h4>Update Status</h4>
        <div className="toggle-group">
          <button
            type="button"
            className={`btn-toggle ${availability === 'Available' ? 'active-available' : ''}`}
            onClick={() => handleToggle('Available')}
            disabled={loading || !isEligibleNow}
            title={!isEligibleNow ? 'Cannot mark Available while in recovery period' : ''}
          >
            Mark Available
          </button>
          <button
            type="button"
            className={`btn-toggle ${availability === 'Unavailable' ? 'active-unavailable' : ''}`}
            onClick={() => handleToggle('Unavailable')}
            disabled={loading}
          >
            Mark Unavailable
          </button>
        </div>

        <form onSubmit={handleDateSubmit} className="date-form">
          <label htmlFor="donation-date">
            <strong>Record Recent Blood Donation Date:</strong>
          </label>
          <div className="date-input-group">
            <input
              id="donation-date"
              type="date"
              max={todayStr}
              value={lastDonationDate}
              onChange={(e) => setLastDonationDate(e.target.value)}
              required
            />
            <button type="submit" disabled={loading} className="btn-record">
              {loading ? 'Saving...' : 'Save & Set Cooldown'}
            </button>
          </div>
          <small className="form-hint">
            * Automatically sets next eligible donation date 90 days ahead and sends reminders when ready.
          </small>
        </form>

        <div className="reminder-box">
          <div>
            <strong>Automatic Availability Reminders:</strong>
            <p>Donors receive automatic email & SMS reminders once their recovery period completes.</p>
          </div>
          <button
            type="button"
            className="btn-reminder"
            onClick={handleCheckReminders}
            disabled={reminderLoading}
          >
            {reminderLoading ? 'Checking...' : '🔔 Run Reminder Check Now'}
          </button>
        </div>

        {message && (
          <div className={`message-banner ${messageType === 'success' ? 'msg-success' : 'msg-error'}`}>
            {message}
          </div>
        )}
      </div>
    </div>
  )
}
