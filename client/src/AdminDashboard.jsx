import { useState, useEffect, useCallback } from 'react'
import { useAuth } from './AuthContext'
import { API_URL } from './config'
import './AdminDashboard.css'

export default function AdminDashboard() {
  const { token, isAdmin } = useAuth()
  const [stats, setStats] = useState(null)
  const [users, setUsers] = useState([])
  const [activeTab, setActiveTab] = useState('stats')
  const [actionMsg, setActionMsg] = useState('')

  const fetchAdminData = useCallback(async () => {
    if (!token || !isAdmin) return
    try {
      const [resStats, resUsers] = await Promise.all([
        fetch(`${API_URL}/api/admin/stats`, {
          headers: { Authorization: `Bearer ${token}` }
        }),
        fetch(`${API_URL}/api/admin/users`, {
          headers: { Authorization: `Bearer ${token}` }
        })
      ])

      const dataStats = await resStats.json()
      const dataUsers = await resUsers.json()

      if (dataStats.success) setStats(dataStats.stats)
      if (dataUsers.success) setUsers(dataUsers.users)
    } catch (e) {
      console.error(e)
    }
  }, [token, isAdmin])

  useEffect(() => {
    fetchAdminData()
  }, [fetchAdminData])

  const triggerReminders = async () => {
    try {
      const res = await fetch(`${API_URL}/api/donors/availability/reminders/trigger`, {
        method: 'POST'
      })
      const data = await res.json()
      setActionMsg(`Reminders triggered: ${data.result?.processedCount || 0} donors notified!`)
      fetchAdminData()
    } catch {
      setActionMsg('Failed to trigger reminders.')
    }
  }

  if (!isAdmin) return null

  return (
    <div className="admin-container">
      <div className="admin-header">
        <div>
          <h2>🛡️ Admin Management Console</h2>
          <p>Real-time system health, role-based access control, and emergency dispatch metrics.</p>
        </div>
        <div className="admin-tabs">
          <button
            className={`adm-tab ${activeTab === 'stats' ? 'active' : ''}`}
            onClick={() => setActiveTab('stats')}
          >
            Overview & Stats
          </button>
          <button
            className={`adm-tab ${activeTab === 'users' ? 'active' : ''}`}
            onClick={() => setActiveTab('users')}
          >
            Users & Roles ({users.length})
          </button>
        </div>
      </div>

      {actionMsg && <div className="admin-msg-banner">{actionMsg}</div>}

      {activeTab === 'stats' && stats && (
        <>
          <div className="stats-cards-grid">
            <div className="stat-card">
              <span className="stat-num">{stats.totalDonors}</span>
              <span className="stat-label">Registered Donors</span>
              <small className="stat-sub">{stats.availableDonors} currently Available</small>
            </div>

            <div className="stat-card">
              <span className="stat-num text-red">{stats.emergencyRequests}</span>
              <span className="stat-label">🚨 Emergency Alerts</span>
              <small className="stat-sub">Pending immediate matching</small>
            </div>

            <div className="stat-card">
              <span className="stat-num">{stats.totalRequests}</span>
              <span className="stat-label">Total Blood Requests</span>
              <small className="stat-sub">{stats.pendingRequests} Pending</small>
            </div>

            <div className="stat-card">
              <span className="stat-num text-green">{stats.fulfilledRequests}</span>
              <span className="stat-label">Lives Saved (Fulfilled)</span>
              <small className="stat-sub">{stats.acceptedRequests} In-Progress</small>
            </div>
          </div>

          <div className="admin-quick-actions">
            <h3>Automated Tasks & Alerts</h3>
            <div className="action-buttons-row">
              <button className="btn-adm-action" onClick={triggerReminders}>
                ⏰ Force Run 90-Day Eligibility Reminders
              </button>
              <button className="btn-adm-action" onClick={fetchAdminData}>
                🔄 Refresh Live Statistics
              </button>
            </div>
          </div>
        </>
      )}

      {activeTab === 'users' && (
        <div className="users-table-container">
          <table className="users-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Role</th>
                <th>Blood Group</th>
                <th>Email</th>
                <th>Phone</th>
                <th>City</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u._id}>
                  <td><strong>{u.name}</strong></td>
                  <td>
                    <span className={`role-badge badge-${u.role}`}>
                      {u.role.toUpperCase()}
                    </span>
                  </td>
                  <td>{u.bloodGroup || '—'}</td>
                  <td>{u.email}</td>
                  <td>{u.phone}</td>
                  <td>{u.city || '—'}</td>
                  <td>
                    {u.role === 'donor' ? (
                      <span className={u.availability === 'Available' ? 'tag-avail' : 'tag-unavail'}>
                        {u.availability}
                      </span>
                    ) : (
                      'Active'
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
