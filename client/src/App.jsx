import { useState } from 'react'
import './App.css'
import { AuthProvider, useAuth } from './AuthContext'
import NotificationCenter from './NotificationCenter'
import AuthModal from './AuthModal'
import DonorAvailability from './DonorAvailability'
import BloodRequestManager from './BloodRequestManager'
import AdminDashboard from './AdminDashboard'
import Register from './Register'
import DonorSearch from './DonorSearch'
import BloodGroupModal from './BloodGroupModal'

function MainContent() {
  const { user, logout, isAuthenticated, isDonor, isRequester, isAdmin } = useAuth()
  const [currentPage, setCurrentPage] = useState('home')
  const [authModalOpen, setAuthModalOpen] = useState(false)
  const [authMode, setAuthMode] = useState('login')
  const [authRole, setAuthRole] = useState('donor')
  const [selectedBloodGroup, setSelectedBloodGroup] = useState(null)

  const openAuth = (mode = 'login', role = 'donor') => {
    setAuthMode(mode)
    setAuthRole(role)
    setAuthModalOpen(true)
  }

  const navigateTo = (page) => {
    setCurrentPage(page)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const bloodGroups = [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-'
  ]

  return (
    <div className="app">
      {/* NAVBAR */}
      <nav className="navbar">
        <div className="logo clickable-logo" onClick={() => navigateTo('home')}>
          🩸 BloodBridge
        </div>

        {/* Multi-Page Navigation Bar */}
        <div className="nav-links">
          <button
            type="button"
            className={`nav-link-btn ${currentPage === 'home' ? 'active' : ''}`}
            onClick={() => navigateTo('home')}
          >
            Home
          </button>

          <button
            type="button"
            className={`nav-link-btn ${currentPage === 'requests' ? 'active' : ''}`}
            onClick={() => navigateTo('requests')}
          >
            Live Requests
          </button>

          <button
            type="button"
            className={`nav-link-btn ${currentPage === 'find-donors' ? 'active' : ''}`}
            onClick={() => navigateTo('find-donors')}
          >
            Find Donors
          </button>

          <button
            type="button"
            className={`nav-link-btn ${currentPage === 'blood-groups' ? 'active' : ''}`}
            onClick={() => navigateTo('blood-groups')}
          >
            Blood Groups
          </button>

          {isDonor && (
            <button
              type="button"
              className={`nav-link-btn ${currentPage === 'availability' ? 'active' : ''}`}
              onClick={() => navigateTo('availability')}
            >
              My Availability
            </button>
          )}

          {isAdmin && (
            <button
              type="button"
              className={`nav-link-btn ${currentPage === 'admin' ? 'active' : ''}`}
              onClick={() => navigateTo('admin')}
            >
              Admin Console
            </button>
          )}

          <button
            type="button"
            className={`nav-link-btn ${currentPage === 'about' ? 'active' : ''}`}
            onClick={() => navigateTo('about')}
          >
            About
          </button>
        </div>

        <div className="nav-actions">
          {isAuthenticated ? (
            <>
              <NotificationCenter />

              <div className="user-badge-container">
                <span className="user-name">{user.name}</span>
                <span className={`user-role-pill ${user.role}`}>
                  {user.role} {user.bloodGroup ? `(${user.bloodGroup})` : ''}
                </span>
              </div>

              <button className="btn-signout" onClick={logout}>
                Sign Out
              </button>
            </>
          ) : (
            <button className="btn-signin" onClick={() => openAuth('login', 'donor')}>
              Sign In / Register
            </button>
          )}
        </div>
      </nav>

      {/* PAGE 1: HOME PAGE */}
      {currentPage === 'home' && (
        <main className="page-container">
          {/* HERO */}
          <section className="hero">
            <div className="hero-content">
              <div className="tagline">REAL-TIME BLOOD DONATION NETWORK</div>
              <h1>
                Every Drop Counts. <span>Every Life Matters.</span>
              </h1>
              <p className="hero-description">
                BloodBridge connects patients and hospitals with matching, available blood
                donors through instant real-time alerts, automated eligibility management,
                and direct emergency dispatch.
              </p>

              <div className="hero-buttons">
                <button
                  type="button"
                  className="primary-button"
                  onClick={() => navigateTo('requests')}
                >
                  View Live Requests 🚨
                </button>

                <button
                  type="button"
                  className="secondary-button"
                  onClick={() => navigateTo('find-donors')}
                >
                  Find a Donor 🔍
                </button>

                {!isAuthenticated && (
                  <button
                    type="button"
                    className="secondary-button"
                    onClick={() => navigateTo('register')}
                  >
                    Become a Donor 🩸
                  </button>
                )}
              </div>
            </div>

            <div className="hero-image">
              <div className="blood-icon">🩸</div>
              <h2>Instant Matching</h2>
              <p>
                Real-time notifications sent via Socket.IO, Nodemailer, & SMS API when urgent blood is requested.
              </p>
            </div>
          </section>

          {/* STATISTICS */}
          <section className="statistics">
            <div>
              <h2>8</h2>
              <p>Blood Groups Supported</p>
            </div>
            <div>
              <h2>&lt; 500ms</h2>
              <p>Real-Time Alert Speed</p>
            </div>
            <div>
              <h2>90 Days</h2>
              <p>Clinical Cooldown Tracking</p>
            </div>
            <div>
              <h2>24/7</h2>
              <p>Emergency Dispatch Network</p>
            </div>
          </section>

          {/* BLOOD GROUPS PREVIEW */}
          <section className="blood-section">
            <h2>Available Blood Groups & Compatibility</h2>
            <p className="section-description">
              Click any blood group to view registered donors and compatibility matrices.
            </p>

            <div className="blood-grid">
              {bloodGroups.map((group) => (
                <div
                  className="blood-card clickable-blood-card"
                  key={group}
                  onClick={() => setSelectedBloodGroup(group)}
                  title={`Click to view registered ${group} donors`}
                >
                  <span>🩸</span>
                  <h3>{group}</h3>
                  <p className="card-click-hint">Click to View Donors →</p>
                </div>
              ))}
            </div>
          </section>
        </main>
      )}

      {/* PAGE 2: LIVE REQUESTS & EMERGENCY DISPATCH */}
      {currentPage === 'requests' && (
        <main className="page-container">
          <BloodRequestManager />
        </main>
      )}

      {/* PAGE 3: FIND DONORS */}
      {currentPage === 'find-donors' && (
        <main className="page-container">
          <DonorSearch />
        </main>
      )}

      {/* PAGE 4: BLOOD GROUPS & COMPATIBILITY */}
      {currentPage === 'blood-groups' && (
        <main className="page-container">
          <section className="blood-section">
            <h2>Available Blood Groups & Compatibility Matrix</h2>
            <p className="section-description">
              Select any blood group below to view its clinical compatibility rules and inspect active registered donors.
            </p>

            <div className="blood-grid">
              {bloodGroups.map((group) => (
                <div
                  className="blood-card clickable-blood-card"
                  key={group}
                  onClick={() => setSelectedBloodGroup(group)}
                  title={`Click to view registered ${group} donors`}
                >
                  <span>🩸</span>
                  <h3>{group}</h3>
                  <p className="card-click-hint">Click to View Donors →</p>
                </div>
              ))}
            </div>
          </section>
        </main>
      )}

      {/* PAGE 5: DONOR AVAILABILITY MANAGEMENT (For Donors) */}
      {currentPage === 'availability' && isDonor && (
        <main className="page-container">
          <DonorAvailability />
        </main>
      )}

      {/* PAGE 6: ADMIN DASHBOARD (For Admins) */}
      {currentPage === 'admin' && isAdmin && (
        <main className="page-container">
          <AdminDashboard />
        </main>
      )}

      {/* PAGE 7: REGISTER DONOR */}
      {currentPage === 'register' && (
        <main className="page-container">
          <Register />
        </main>
      )}

      {/* PAGE 8: ABOUT PAGE */}
{currentPage === 'about' && (
  <main className="page-container about-page">

    {/* HERO SECTION */}
    <section className="about-hero">
      <div className="about-hero-content">
        <div className="section-tag">ABOUT OUR PLATFORM</div>
        <h1>
          Connecting donors.
          <br />
          <span>Saving lives.</span>
        </h1>
        <p>
          BloodBridge brings donors, patients, and hospitals together
          through a simple, dependable blood donation network.
          Our platform makes finding blood donors easier and faster.
        </p>
      </div>

      <div className="about-hero-art">
        <div className="about-drop">🩸</div>
        <div className="about-art-caption">
          <strong>Every Drop Counts</strong>
          <span>Every Connection Matters</span>
        </div>
      </div>
    </section>

    {/* MISSION AND VISION */}
    <section className="about-mission-grid">
      <article className="about-info-card">
        <span className="about-card-icon">🎯</span>
        <div className="section-tag">OUR MISSION</div>
        <h2>Make Finding Blood Easier and Faster</h2>
        <p>
          We aim to reduce delays during blood emergencies by helping
          people find matching donors and share urgent requests
          through one reliable platform.
        </p>
      </article>

      <article className="about-info-card">
        <span className="about-card-icon">🌍</span>
        <div className="section-tag">OUR VISION</div>
        <h2>A Connected Community of Donors</h2>
        <p>
          We envision a community where people can coordinate
          blood donations quickly, responsibly, and with confidence.
        </p>
      </article>
    </section>

    {/* FEATURES */}
    <section className="about-features">
      <div className="about-section-heading">
        <div className="section-tag">WHAT WE OFFER</div>
        <h2>Designed to Make Every Connection Count</h2>
        <p>
          Helpful tools for donors, requesters, and administrators.
        </p>
      </div>

      <div className="about-feature-grid">
        <article className="about-feature-card">
          <span>🔎</span>
          <h3>Donor Matching</h3>
          <p>
            Find donors by blood group and availability to make
            searching more focused.
          </p>
        </article>

        <article className="about-feature-card">
          <span>⚡</span>
          <h3>Live Requests</h3>
          <p>
            Share urgent blood requirements and track requests
            in one place.
          </p>
        </article>

        <article className="about-feature-card">
          <span>🔔</span>
          <h3>Notifications</h3>
          <p>
            Receive updates that help users stay informed about
            requests and activity.
          </p>
        </article>

        <article className="about-feature-card">
          <span>🛡️</span>
          <h3>Role-Based Access</h3>
          <p>
            Separate experiences for donors, requesters,
            and administrators.
          </p>
        </article>
      </div>
    </section>

    {/* HOW IT WORKS */}
    <section className="about-how">
      <div className="about-section-heading">
        <div className="section-tag">HOW IT WORKS</div>
        <h2>Simple Steps. Meaningful Impact.</h2>
      </div>

      <div className="about-steps">
        <article>
          <span className="about-step-number">01</span>
          <h3>Join the Network</h3>
          <p>Create an account as a donor or requester.</p>
        </article>

        <article>
          <span className="about-step-number">02</span>
          <h3>Find or Share</h3>
          <p>Search for matching donors or post a blood request.</p>
        </article>

        <article>
          <span className="about-step-number">03</span>
          <h3>Stay Connected</h3>
          <p>Follow updates and coordinate through the platform.</p>
        </article>
      </div>
    </section>

    {/* BOTTOM BANNER */}
    <section className="about-bottom-banner">
      <div>
        <h2>Be Part of the Connection.</h2>
        <p>
          One community can make a difference when someone needs blood.
        </p>
      </div>
      <span className="about-banner-drop">🩸</span>
    </section>

  </main>
)}

      {/* FOOTER */}
      <footer id="contact">
        <h2>🩸 BloodBridge</h2>
        <p>Connecting Donors. Saving Lives in Real-Time.</p>
        <p>© 2026 BloodBridge. All Rights Reserved.</p>
      </footer>

      {/* Auth Modal (Login / Register) */}
      <AuthModal
        isOpen={authModalOpen}
        onClose={() => setAuthModalOpen(false)}
        initialMode={authMode}
        initialRole={authRole}
      />

      {/* Blood Group Donors Detail Modal */}
      <BloodGroupModal
        bloodGroup={selectedBloodGroup}
        onClose={() => setSelectedBloodGroup(null)}
        onRegisterClick={() => {
          setSelectedBloodGroup(null)
          navigateTo('register')
        }}
      />
    </div>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <MainContent />
    </AuthProvider>
  )
}
