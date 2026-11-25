const { spawn, execSync } = require('child_process')
const path = require('path')

console.log('🩸 Preparing BloodBridge Full Stack (Server + Client)...\n')

// Ensure port 5000 is clean and not occupied by an orphaned process
try {
  const netstatOutput = execSync('netstat -ano', { encoding: 'utf8' })
  const lines = netstatOutput.split('\n')
  for (const line of lines) {
    if (line.includes(':5000') && line.includes('LISTENING')) {
      const parts = line.trim().split(/\s+/)
      const pid = parts[parts.length - 1]
      if (pid && pid !== '0' && pid !== process.pid.toString()) {
        console.log(`🧹 Freeing port 5000 from stale process PID ${pid}...`)
        try {
          execSync(`taskkill /F /PID ${pid}`)
        } catch {}
      }
    }
  }
} catch (e) {
  // Ignored if port is already free
}

console.log('🚀 Launching Backend Server & Frontend Client...\n')

const serverProcess = spawn('npm', ['run', 'dev'], {
  cwd: path.join(__dirname, 'bloodbridge', 'server'),
  shell: true,
  stdio: 'inherit'
})

const clientProcess = spawn('npm', ['run', 'dev'], {
  cwd: path.join(__dirname, 'bloodbridge', 'client'),
  shell: true,
  stdio: 'inherit'
})

const cleanup = () => {
  console.log('\n🛑 Shutting down BloodBridge services...')
  serverProcess.kill()
  clientProcess.kill()
  process.exit(0)
}

process.on('SIGINT', cleanup)
process.on('SIGTERM', cleanup)
