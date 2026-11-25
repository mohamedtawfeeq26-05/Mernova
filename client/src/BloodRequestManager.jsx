import { useState, useEffect, useCallback } from 'react'
import { useAuth } from './AuthContext'
import { socket } from './socket'
import { API_URL } from './config'
import './BloodRequestManager.css'

export default function BloodRequestManager() {
  const { user, token, isDonor, isRequester, isAdmin } = useAuth()

  const [requests, setRequests] = useState([])
  const [loading, setLoading] = useState(false)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [actionLoading, setActionLoading] = useState(false)
  const [statusMessage, setStatusMessage] = useState('')

  const [formData, setFormData] = useState({
    patientName: '',
    hospitalName: '',
    bloodGroup: 'O+',
    unitsRequired: 1,
    urgency: 'Emergency',
    city: user?.city || '',
    address: '',
    contactPhone: user?.phone || '',
    notes: ''
  })

  const fetchRequests = useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch(`${API_URL}/api/requests`)
      const data = await res.json()
      if (data.success) {
        setRequests(data.requests)
      }
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchRequests()

    const handleNewRequest = (data) => {
      setRequests((prev) => [data.bloodRequest, ...prev])
    }

    const handleRequestAccepted = (data) => {
      setRequests((prev) =>
        prev.map((r) =>
          r._id === data.bloodRequestId
            ? { ...r, status: 'Accepted', acceptedBy: data.donor }
            : r
        )
      )
    }

    socket.on('blood_request_created', handleNewRequest)
    socket.on('request_accepted', handleRequestAccepted)

    return () => {
      socket.off('blood_request_created', handleNewRequest)
      socket.off('request_accepted', handleRequestAccepted)
    }
  }, [fetchRequests])

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value })
  }

  const handleCreateRequest = async (e) => {
    e.preventDefault()
    if (!token) return

    setActionLoading(true)
    setStatusMessage('')
    try {
      const res = await fetch(`${API_URL}/api/requests`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          ...formData,
          unitsRequired: Number(formData.unitsRequired)
        })
      })

      const data = await res.json()
      if (!res.ok) throw new Error(data.message || 'Failed to create request')

      setStatusMessage(data.message)
      setShowCreateModal(false)
      fetchRequests()
    } catch (err) {
      alert(err.message)
    } finally {
      setActionLoading(false)
    }
  }

  const handleAcceptRequest = async (requestId) => {
    if (!token) {
      alert('Please log in as a Donor to accept blood requests.')
      return
    }

    if (!confirm('Are you sure you want to accept this request? The requester and hospital will be immediately notified with your contact details.')) {
      return
    }

    setActionLoading(true)
    try {
      const res = await fetch(`${API_URL}/api/requests/${requestId}/accept`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`
        }
      })

      const data = await res.json()
      if (!res.ok) throw new Error(data.message || 'Failed to accept request')

      alert(data.message)
      fetchRequests()
    } catch (err) {
      alert(err.message)
    } finally {
      setActionLoading(false)
    }
  }

  const handleUpdateStatus = async (requestId, newStatus) => {
    try {
      const res = await fetch(`${API_URL}/api/requests/${requestId}/status`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ status: newStatus })
      })
      const data = await res.json()
      if (res.ok) {
        fetchRequests()
      } else {
        alert(data.message)
      }
    } catch (e) {
      alert(e.message)
    }
  }

  return (
    <div className="request-manager-container">
      <div className="manager-header">
        <div>
          <h2>🚨 Live Blood Requests & Emergency Dispatch</h2>
          <p>Real-time matching and immediate alerts via Socket.IO, Nodemailer, and SMS API.</p>
        </div>

        {(isRequester || isAdmin) && (
          <button className="btn-create-request" onClick={() => setShowCreateModal(true)}>
            + Post Blood Request
          </button>
        )}
      </div>

      {statusMessage && (
        <div className="status-banner">
          {statusMessage}
        </div>
      )}

      {showCreateModal && (
        <div className="modal-backdrop">
          <div className="request-modal">
            <button className="modal-close" onClick={() => setShowCreateModal(false)}>✕</button>
            <h3>Create Blood Request</h3>
            <p>Donors matching the requested blood group will be instantly alerted.</p>

            <form onSubmit={handleCreateRequest} className="request-form">
              <div className="form-row">
                <div className="form-group">
                  <label>Patient Name *</label>
                  <input
                    type="text"
                    name="patientName"
                    required
                    placeholder="Patient name"
                    value={formData.patientName}
                    onChange={handleChange}
                  />
                </div>
                <div className="form-group">
                  <label>Blood Group Required *</label>
                  <select name="bloodGroup" value={formData.bloodGroup} onChange={handleChange} required>
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
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Units Required *</label>
                  <input
                    type="number"
                    name="unitsRequired"
                    min="1"
                    max="10"
                    required
                    value={formData.unitsRequired}
                    onChange={handleChange}
                  />
                </div>
                <div className="form-group">
                  <label>Urgency Level *</label>
                  <select name="urgency" value={formData.urgency} onChange={handleChange} required>
                    <option value="Normal">Normal (Routine)</option>
                    <option value="Emergency">🚨 Emergency (Immediate Need)</option>
                    <option value="Critical">⚠️ Critical / Trauma</option>
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label>Hospital Name *</label>
                <input
                  type="text"
                  name="hospitalName"
                  required
                  placeholder="e.g. City General Hospital"
                  value={formData.hospitalName}
                  onChange={handleChange}
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>City *</label>
                  <input
                    type="text"
                    name="city"
                    required
                    placeholder="e.g. Mumbai, Delhi, Bangalore"
                    value={formData.city}
                    onChange={handleChange}
                  />
                </div>
                <div className="form-group">
                  <label>Contact Phone (For SMS/Coordination) *</label>
                  <input
                    type="tel"
                    name="contactPhone"
                    required
                    placeholder="10-digit mobile"
                    value={formData.contactPhone}
                    onChange={handleChange}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Hospital Address / Room No.</label>
                <input
                  type="text"
                  name="address"
                  required
                  placeholder="Address or Ward detail"
                  value={formData.address}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label>Additional Clinical Notes (Optional)</label>
                <textarea
                  name="notes"
                  placeholder="Reason, surgery schedule, replacement details..."
                  value={formData.notes}
                  onChange={handleChange}
                />
              </div>

              <button type="submit" className="btn-submit-request" disabled={actionLoading}>
                {actionLoading ? 'Dispatching Real-time Alerts...' : 'Broadcast Blood Request'}
              </button>
            </form>
          </div>
        </div>
      )}

      <div className="requests-feed">
        {loading ? (
          <p className="feed-loading">Loading live blood requests...</p>
        ) : requests.length === 0 ? (
          <div className="feed-empty">
            <p>No active blood requests at the moment.</p>
          </div>
        ) : (
          <div className="requests-grid">
            {requests.map((req) => {
              const isEmergency = req.urgency === 'Emergency' || req.urgency === 'Critical'
              const isAccepted = req.status === 'Accepted'

              return (
                <div
                  key={req._id}
                  className={`request-card ${isEmergency ? 'card-emergency' : ''} ${
                    isAccepted ? 'card-accepted' : ''
                  }`}
                >
                  <div className="req-card-header">
                    <div className="group-badge">{req.bloodGroup}</div>
                    <div className="req-meta">
                      <span className={`urgency-badge urgency-${req.urgency.toLowerCase()}`}>
                        {isEmergency ? '🚨 ' : ''}
                        {req.urgency}
                      </span>
                      <span className={`status-badge status-${req.status.toLowerCase()}`}>
                        {req.status}
                      </span>
                    </div>
                  </div>

                  <div className="req-card-body">
                    <h3>{req.patientName}</h3>
                    <p className="hospital-text">🏥 <strong>{req.hospitalName}</strong>, {req.city}</p>
                    <p className="units-text">🩸 Units Needed: <strong>{req.unitsRequired} Unit(s)</strong></p>
                    <p className="phone-text">📞 Contact: <strong>{req.contactPhone}</strong></p>
                    {req.address && <p className="address-text">📍 {req.address}</p>}
                    {req.notes && <p className="notes-text">📝 &ldquo;{req.notes}&rdquo;</p>}

                    {isAccepted && req.acceptedBy && (
                      <div className="accepted-banner">
                        ✓ <strong>Accepted by Donor:</strong> {req.acceptedBy.name || 'Anonymous Donor'} ({req.acceptedBy.bloodGroup || req.bloodGroup})
                      </div>
                    )}
                  </div>

                  <div className="req-card-footer">
                    {isDonor && req.status === 'Pending' && (
                      <button
                        className="btn-accept"
                        onClick={() => handleAcceptRequest(req._id)}
                        disabled={actionLoading}
                      >
                        ❤️ Accept to Donate
                      </button>
                    )}

                    {(isAdmin || (isRequester && req.requester?._id === user?._id)) && (
                      <div className="admin-actions">
                        {req.status === 'Accepted' && (
                          <button
                            className="btn-fulfill"
                            onClick={() => handleUpdateStatus(req._id, 'Fulfilled')}
                          >
                            Mark Fulfilled
                          </button>
                        )}
                        {req.status === 'Pending' && (
                          <button
                            className="btn-cancel"
                            onClick={() => handleUpdateStatus(req._id, 'Cancelled')}
                          >
                            Cancel
                          </button>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
