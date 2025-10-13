# Sewercide Plumbing CTF Challenge

## Overview

This is a network-based penetration testing challenge where you start from a Kali Linux attack machine and must discover and exploit a vulnerable web server.

### Goal

Find and retrieve the flag from the target server on the network.

## Your Environment

You will be provided access to a **Kali Linux 2025.2** machine with standard penetration testing tools.

**Credentials:**
- Username: `kali`
- Password: `kali`

## Challenge Approach

1. **Reconnaissance**: Discover hosts and services on the network
2. **Enumeration**: Identify running services and potential vulnerabilities
3. **Exploitation**: Exploit discovered vulnerabilities
4. **Flag Capture**: Retrieve the flag from the target system

## Tools Available

Your Kali Linux machine includes (but is not limited to):
- `nmap` - Network scanner
- `curl`, `wget` - HTTP clients
- `burpsuite` - Web application testing
- `ssh` - Secure shell client
- Standard Unix utilities

## Tips

- Start with network reconnaissance
- Services may be running on non-standard ports
- Web forms are often a good attack vector
- Look for ways to read sensitive files from the server
- SSH keys can be valuable for lateral movement

## Scoring

Successfully retrieving the flag awards **100 points**.

## About

This challenge tests your ability to:
- Perform network reconnaissance
- Identify web application vulnerabilities
- Exploit input validation issues
- Extract sensitive information
- Use exfiltrated credentials for access

Good luck!
