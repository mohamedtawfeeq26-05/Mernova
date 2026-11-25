import { createContext, useContext, useState, useEffect } from 'react'
import { socket } from './socket'

const AuthContext = createContext(null)

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    try {
      const savedUser = localStorage.getItem('bloodbridge_user')
      return savedUser ? JSON.parse(savedUser) : null
    } catch {
      return null
    }
  })

  const [token, setToken] = useState(() => {
    return localStorage.getItem('bloodbridge_token') || null
  })

  useEffect(() => {
    if (token) {
      localStorage.setItem('bloodbridge_token', token)
    } else {
      localStorage.removeItem('bloodbridge_token')
    }
  }, [token])

  useEffect(() => {
    if (user) {
      localStorage.setItem('bloodbridge_user', JSON.stringify(user))

      socket.emit('join_user_room', user._id)

      if (user.role === 'donor' && user.bloodGroup) {
        socket.emit('join_blood_room', user.bloodGroup)
      }
    } else {
      localStorage.removeItem('bloodbridge_user')
    }
  }, [user])

  const login = (userData, userToken) => {
    setUser(userData)
    setToken(userToken)
  }

  const logout = () => {
    if (user) {
      socket.emit('leave_user_room', user._id)
    }
    setUser(null)
    setToken(null)
    localStorage.removeItem('bloodbridge_token')
    localStorage.removeItem('bloodbridge_user')
  }

  const updateUser = (updatedFields) => {
    setUser((prev) => ({
      ...prev,
      ...updatedFields
    }))
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        login,
        logout,
        updateUser,
        isAuthenticated: !!token && !!user,
        isDonor: user?.role === 'donor',
        isRequester: user?.role === 'requester',
        isAdmin: user?.role === 'admin'
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
