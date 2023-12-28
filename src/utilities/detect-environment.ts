import fs from 'node:fs'
import { providerInfo, runtime } from 'std-env'

export const environmentInfo = {
  isDocker: isDocker(),
  isCI: Boolean(providerInfo.ci),
  provider: providerInfo.name,
  runtime: runtime
}

function isDocker() {
  let isDockerCached: boolean | undefined
  isDockerCached ??= hasDockerEnv() || hasDockerCGroup()
  return isDockerCached
}

function hasDockerEnv() {
  try {
    fs.statSync('/.dockerenv')
    return true
  } catch {
    return false
  }
}

function hasDockerCGroup() {
  try {
    return fs.readFileSync('/proc/self/cgroup', 'utf8').includes('docker')
  } catch {
    return false
  }
}
