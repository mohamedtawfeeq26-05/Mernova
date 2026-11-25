import { useState, useEffect } from 'react'
import { API_URL } from './config'
import './BloodGroupModal.css'

// Medical compatibility guide
const compatibilityInfo = {
  'O-': {
    canDonateTo: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], // Universal Donor
    canReceiveFrom: ['O-'],
    tag: '🌟 Universal Donor'
  },
  'O+': {
    canDonateTo: ['O+', 'A+', 'B+', 'AB+'],
    canReceiveFrom: ['O+', 'O-'],
    tag: 'Most Needed'
  },
  'A-': {
    canDonateTo: ['A-', 'A+', 'AB-', 'AB+'],
    canReceiveFrom: ['A-', 'O-'],
    tag: 'Rare Blood Group'
  },
  'A+': {
    canDonateTo: ['A+', 'AB+'],
    canReceiveFrom: ['A+', 'A-', 'O+', 'O-'],
    tag: 'High Demand'
  },
  'B-': {
    canDonateTo: ['B-', 'B+', 'AB-', 'AB+'],
    canReceiveFrom: ['B-', 'O-'],
    tag: 'Rare Blood Group'
  },
  'B+': {
    canDonateTo: ['B+', 'AB+'],
    canReceiveFrom: ['B+', 'B-', 'O+', 'O-'],
    tag: 'Common in South Asia'
  },
  'AB-': {
    canDonateTo: ['AB-', 'AB+'],
    canReceiveFrom: ['AB-', 'A-', 'B-', 'O-'],
    tag: 'Rarest Blood Group'
  },
  'AB+': {
    canDonateTo: ['AB+'],
    canReceiveFrom: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], // Universal Recipient
    tag: '🌟 Universal Recipient'
  }
}

export default function BloodGroupModal({ bloodGroup, onClose, onRegisterClick }) {
  const [donors, setDonors] = useState([])
  const [loading, setLoading] = useState(true)
  const [copiedId, setCopiedId] = useState(null)

  useEffect(() => {
    if (!bloodGroup) return

    setLoading(true)
    fetch(`${API_URL}/api/donors/search?bloodGroup=${encodeURIComponent(bloodGroup)}`)
      .then((res) => res.json())
      .then((data) => {
        if (data.success) {
          setDonors(data.donors)
        }
      })
      .catch((err) => console.error('Error fetching donors:', err))
      .finally(() => setLoading(false))
  }, [bloodGroup])

  if (!bloodGroup) return null

  const info = compatibilityInfo[bloodGroup] || {}

  const handleCopyPhone = (id, phone) => {
    navigator.clipboard.writeText(phone)
    setCopiedId(id)
    setTimeout(() => setCopiedId(null), 2000)
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="blood-group-modal" onClick={(e) => e.stopPropagation()}>
        <button className="modal-close" onClick={onClose}>✕</button>

        {/* Header */}
        <div className="bg-modal-header">
          <div className="bg-badge-large">{bloodGroup}</div>
          <div>
            <h2>Blood Group {bloodGroup} Donors</h2>
            <p className="bg-tagline">{info.tag || 'Registered Donors'}</p>
          </div>
        </div>

        {/* Compatibility Matrix Info */}
        <div className="compatibility-matrix">
          <div className="compat-item">
            <span className="compat-label">Can Donate Blood To:</span>
            <div className="compat-tags">
              {info.canDonateTo?.map((g) => (
                <span key={g} className="group-tag donate">{g}</span>
              ))}
            </div>
          </div>
          <div className="compat-item">
            <span className="compat-label">Can Receive Blood From:</span>
            <div className="compat-tags">
              {info.canReceiveFrom?.map((g) => (
                <span key={g} className="group-tag receive">{g}</span>
              ))}
            </div>
          </div>
        </div>

        {/* Donors List Section */}
        <div className="donors-list-section">
          <h3>
            Registered {bloodGroup} Donors ({donors.length})
          </h3>

          {loading ? (
            <div className="donors-loading">
              <span className="spinner">🩸</span>
              <p>Searching registered donors...</p>
            </div>
          ) : donors.length === 0 ? (
            <div className="no-donors-box">
              <p>No donors registered yet for <strong>{bloodGroup}</strong> in the database.</p>
              {onRegisterClick && (
                <button
                  className="btn-become-first"
                  onClick={() => {
                    onClose()
                    onRegisterClick()
                  }}
                >
                  Be the First {bloodGroup} Donor!
                </button>
              )}
            </div>
          ) : (
            <div className="donors-cards-scroll">
              {donors.map((donor) => {
                const isAvailable = donor.availability === 'Available'
                return (
                  <div
                    key={donor._id}
                    className={`donor-detail-card ${isAvailable ? 'card-avail' : 'card-unavail'}`}
                  >
                    <div className="donor-card-top">
                      <div>
                        <h4>{donor.name}</h4>
                        <span className="donor-sub">
                          {donor.gender || 'Donor'} • {donor.age ? `${donor.age} yrs` : ''} • {donor.city || 'City N/A'}
                        </span>
                      </div>
                      <span className={`donor-status-pill ${isAvailable ? 'pill-green' : 'pill-gray'}`}>
                        {isAvailable ? '● Available' : '○ Unavailable'}
                      </span>
                    </div>

                    <div className="donor-card-body">
                      {donor.address && (
                        <p className="donor-info-row">
                          <span className="info-icon">📍</span>
                          <span>{donor.address}{donor.pincode ? `, ${donor.pincode}` : ''}</span>
                        </p>
                      )}

                      <p className="donor-info-row">
                        <span className="info-icon">🩸</span>
                        <span>
                          Donated: <strong>{donor.totalDonations || 0} times</strong>
                          {donor.lastDonationDate && (
                            <span className="last-donated">
                              {' '}(Last: {new Date(donor.lastDonationDate).toLocaleDateString()})
                            </span>
                          )}
                        </span>
                      </p>

                      {!isAvailable && donor.nextEligibleDate && (
                        <p className="cooldown-notice">
                          ⏳ In 90-day cooldown until {new Date(donor.nextEligibleDate).toLocaleDateString()}
                        </p>
                      )}
                    </div>

                    <div className="donor-card-footer">
                      <a href={`tel:${donor.phone}`} className="btn-call-donor">
                        📞 Call {donor.phone}
                      </a>
                      <button
                        className="btn-copy-phone"
                        onClick={() => handleCopyPhone(donor._id, donor.phone)}
                      >
                        {copiedId === donor._id ? '✓ Copied' : '📋 Copy'}
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
