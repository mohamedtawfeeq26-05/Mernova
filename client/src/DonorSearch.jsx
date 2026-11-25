
import { useState } from 'react'
import { API_URL } from './config'
import './DonorSearch.css'

function DonorSearch() {
  const [bloodGroup, setBloodGroup] = useState('')
  const [city, setCity] = useState('')
  const [donors, setDonors] = useState([])
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSearch = async (e) => {
    e.preventDefault()

    if (!bloodGroup && !city.trim()) {
      setMessage('Please select a blood group or enter a city.')
      setDonors([])
      return
    }

    setLoading(true)
    setMessage('')

    try {
      const params = new URLSearchParams()

      if (bloodGroup) params.append('bloodGroup', bloodGroup)
      if (city.trim()) params.append('city', city.trim())

      const response = await fetch(
        `${API_URL}/api/donors/search?${params.toString()}`
      )

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.message || 'Search failed')
      }

      setDonors(data.donors)

      if (data.donors.length === 0) {
        setMessage('No matching donors found.')
      }

    } catch (error) {
      setMessage(error.message || 'Unable to search donors.')
      setDonors([])
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="donor-search-page">

      <div className="search-container">

        <h1>Find Blood Donors</h1>

        <p>
          Search for registered donors by blood group and city.
        </p>

        <form onSubmit={handleSearch}>

          <label>Blood Group</label>

          <select
            value={bloodGroup}
            onChange={(e) => setBloodGroup(e.target.value)}
          >
            <option value="">All Blood Groups</option>
            <option value="A+">A+</option>
            <option value="A-">A-</option>
            <option value="B+">B+</option>
            <option value="B-">B-</option>
            <option value="AB+">AB+</option>
            <option value="AB-">AB-</option>
            <option value="O+">O+</option>
            <option value="O-">O-</option>
          </select>

          <label>City</label>

          <input
            type="text"
            placeholder="Enter city name"
            value={city}
            onChange={(e) => setCity(e.target.value)}
          />

          <button type="submit" disabled={loading}>
            {loading ? 'Searching...' : 'Search Donors'}
          </button>

        </form>

        {message && (
          <p className="search-message">{message}</p>
        )}

        <div className="donor-results">

          {donors.map((donor) => (
            <div className="donor-card" key={donor._id}>

              <h3>{donor.name}</h3>

              <p>
                <strong>Blood Group:</strong> {donor.bloodGroup}
              </p>

              <p>
                <strong>City:</strong> {donor.city}
              </p>

              <p>
                <strong>Age:</strong> {donor.age}
              </p>

              <p>
                <strong>Gender:</strong> {donor.gender}
              </p>

            </div>
          ))}

        </div>

      </div>

    </div>
  )
}

export default DonorSearch
