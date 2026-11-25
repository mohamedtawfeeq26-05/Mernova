const { spawn, execSync } = require('child_process')
const path = require('path')

console.log('🩸 Preparing BloodBridge Full Stack (Express Backend + Flutter Client)...\n')

// 1. Terminate orphaned dart processes locking the build directory
try {
  execSync('taskkill /F /IM dart.exe', { stdio: 'ignore' })
} catch (e) {
  // Ignored if dart is not running
}

// 2. Ensure port 5000 is clean and not occupied by an orphaned process
try {
  const netstatOutput = execSync('netstat -ano', { encoding: 'utf8' })
  const lines = netstatOutput.split('\n')
  const killedPids = new Set()
  for (const line of lines) {
    if (line.includes(':5000') && line.includes('LISTENING')) {
      const parts = line.trim().split(/\s+/)
      const pid = parts[parts.length - 1]
      if (pid && pid !== '0' && pid !== process.pid.toString() && !killedPids.has(pid)) {
        killedPids.add(pid)
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

// 3. Remove stale build directory if present
try {
  execSync('powershell -Command "Remove-Item -Recurse -Force bloodbridge\\flutter_client\\build -ErrorAction SilentlyContinue"', { stdio: 'ignore' })
} catch (e) {
  // Ignored
}

console.log('🚀 Launching Backend Express Server...\n')

const serverProcess = spawn('npm run dev', {
  cwd: path.join(__dirname, 'bloodbridge', 'server'),
  shell: true,
  stdio: 'inherit'
})

console.log('📱 Launching BloodBridge Flutter Client...\n')

const flutterProcess = spawn('flutter run -d chrome', {
  cwd: path.join(__dirname, 'bloodbridge', 'flutter_client'),
  shell: true,
  stdio: 'inherit'
})

const cleanup = () => {
  console.log('\n🛑 Shutting down BloodBridge services...')
  try { serverProcess.kill() } catch {}
  try { flutterProcess.kill() } catch {}
  try { execSync('taskkill /F /IM dart.exe', { stdio: 'ignore' }) } catch {}
  process.exit(0)
}

process.on('SIGINT', cleanup)
process.on('SIGTERM', cleanup)
