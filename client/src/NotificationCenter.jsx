import { useState, useEffect, useCallback } from 'react'
import { useAuth } from './AuthContext'
import { socket } from './socket'
import { API_URL } from './config'
import './NotificationCenter.css'

export default function NotificationCenter() {
  const { token, isAuthenticated } = useAuth()
  const [notifications, setNotifications] = useState([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [isOpen, setIsOpen] = useState(false)
  const [toast, setToast] = useState(null)

  const fetchNotifications = useCallback(async () => {
    if (!token) return
    try {
      const res = await fetch(`${API_URL}/api/notifications`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      const data = await res.json()
      if (data.success) {
        setNotifications(data.notifications)
        setUnreadCount(data.unreadCount)
      }
    } catch (err) {
      console.error('Failed to load notifications:', err)
    }
  }, [token])

  useEffect(() => {
    if (isAuthenticated) {
      fetchNotifications()
    } else {
      setNotifications([])
      setUnreadCount(0)
    }
  }, [isAuthenticated, fetchNotifications])

  useEffect(() => {
    const handleNewNotification = (data) => {
      const item = data.notification || data
      setNotifications((prev) => [item, ...prev])
      setUnreadCount((c) => c + 1)

      setToast({
        title: item.title,
        message: item.message,
        type: item.type,
        urgency: data.bloodRequest?.urgency
      })

      setTimeout(() => {
        setToast((current) => (current?.title === item.title ? null : current))
      }, 6000)
    }

    const handleEmergencyBroadcast = (data) => {
      setToast({
        title: '🚨 CRITICAL EMERGENCY ALERT',
        message: data.message,
        type: 'EMERGENCY_ALERT',
        urgency: 'Emergency'
      })
      setTimeout(() => setToast(null), 8000)
    }

    socket.on('new_notification', handleNewNotification)
    socket.on('emergency_broadcast', handleEmergencyBroadcast)

    return () => {
      socket.off('new_notification', handleNewNotification)
      socket.off('emergency_broadcast', handleEmergencyBroadcast)
    }
  }, [])

  const markAsRead = async (id) => {
    try {
      await fetch(`${API_URL}/api/notifications/${id}/read`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` }
      })
      setNotifications((prev) =>
        prev.map((n) => (n._id === id ? { ...n, read: true } : n))
      )
      setUnreadCount((c) => Math.max(0, c - 1))
    } catch (e) {
      console.error(e)
    }
  }

  const markAllAsRead = async () => {
    try {
      await fetch(`${API_URL}/api/notifications/read-all`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` }
      })
      setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))
      setUnreadCount(0)
    } catch (e) {
      console.error(e)
    }
  }

  if (!isAuthenticated) return null

  return (
    <div className="notification-center">
      {toast && (
        <div className={`toast-banner ${toast.type === 'EMERGENCY_ALERT' ? 'toast-emergency' : 'toast-normal'}`}>
          <div className="toast-icon">
            {toast.type === 'EMERGENCY_ALERT' ? '🚨' : toast.type === 'REQUEST_ACCEPTED' ? '✅' : '🩸'}
          </div>
          <div className="toast-content">
            <h4>{toast.title}</h4>
            <p>{toast.message}</p>
          </div>
          <button className="toast-close" onClick={() => setToast(null)}>✕</button>
        </div>
      )}

      <button
        className={`bell-button ${unreadCount > 0 ? 'has-unread' : ''}`}
        onClick={() => setIsOpen(!isOpen)}
        title="View Notifications"
      >
        🔔
        {unreadCount > 0 && <span className="notification-badge">{unreadCount}</span>}
      </button>

      {isOpen && (
        <div className="notification-dropdown">
          <div className="dropdown-header">
            <h3>Notifications</h3>
            {unreadCount > 0 && (
              <button className="btn-link" onClick={markAllAsRead}>
                Mark all read
              </button>
            )}
            <button className="btn-close" onClick={() => setIsOpen(false)}>✕</button>
          </div>

          <div className="notification-list">
            {notifications.length === 0 ? (
              <p className="empty-state">No notifications yet.</p>
            ) : (
              notifications.map((n) => (
                <div
                  key={n._id}
                  className={`notification-item ${n.read ? 'read' : 'unread'} ${
                    n.type === 'EMERGENCY_ALERT' ? 'item-emergency' : ''
                  }`}
                  onClick={() => !n.read && markAsRead(n._id)}
                >
                  <div className="item-header">
                    <span className={`tag-type ${n.type}`}>
                      {n.type === 'EMERGENCY_ALERT' ? '🚨 Emergency Alert' :
                       n.type === 'REQUEST_ACCEPTED' ? '✅ Request Accepted' :
                       n.type === 'AVAILABILITY_REMINDER' ? '⏰ Reminder' : '🩸 Request Alert'}
                    </span>
                    <span className="item-time">
                      {new Date(n.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                  <h4>{n.title}</h4>
                  <p>{n.message}</p>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}
