# Sewercide CTF - Network Architecture

## Network Topology

```
                    ┌─────────────────────────────────┐
                    │   Open Cyber Range Platform     │
                    │   (External Access)              │
                    └──────────────┬──────────────────┘
                                   │ SSH
                                   │ Port 22
                    ┌──────────────▼──────────────────┐
                    │   Kali Linux 2025.2             │
                    │   IP: 10.1.1.10/30              │
                    │   Role: Attacker                │
                    │   Credentials: kali / kali      │
                    │                                 │
                    │   Tools:                        │
                    │   - nmap                        │
                    │   - burpsuite                   │
                    │   - curl, wget                  │
                    │   - ssh client                  │
                    │   - metasploit                  │
                    └──────────────┬──────────────────┘
                                   │
                                   │ Internal Network
                                   │ 10.1.1.8/30
                                   │
                    ┌──────────────▼──────────────────┐
                    │   Network Switch                │
                    │   (Virtual Switch)              │
                    └──────────────┬──────────────────┘
                                   │
                                   │
                    ┌──────────────▼──────────────────┐
                    │   Sewercide CTF Server          │
                    │   IP: 10.1.1.9/30               │
                    │   Role: Target                  │
                    │                                 │
                    │   Services:                     │
                    │   - Web (nginx): Port 9999      │
                    │   - SSH: Port 22 (key-only)     │
                    │                                 │
                    │   Flag: /etc/flag_*.txt         │
                    └─────────────────────────────────┘
```

## Network Details

### Subnet Configuration
- **Network**: 10.1.1.8/30
- **Netmask**: 255.255.255.252
- **Usable IPs**: 2 addresses
- **Network Address**: 10.1.1.8
- **First Usable**: 10.1.1.9 (Target Server)
- **Second Usable**: 10.1.1.10 (Kali Linux)
- **Broadcast**: 10.1.1.11

### IP Assignments

| Host | IP Address | Role | Access |
|------|------------|------|--------|
| Sewercide Server | 10.1.1.9/30 | Target | Internal only |
| Kali Linux | 10.1.1.10/30 | Attacker | External SSH + Internal |

## Network Security

### Isolation
- **External to Kali**: SSH allowed (participant entry point)
- **Kali to Target**: All traffic allowed (attack path)
- **External to Target**: Blocked (must go through Kali)

### Access Control
1. Participants SSH into Kali from outside
2. From Kali, participants can reach the target at 10.1.1.9
3. Target server is completely isolated from external access
4. All attacks must originate from Kali machine

## Attack Flow

```
Participant → SSH → Kali (10.1.1.10)
                      ↓
                  nmap scan
                      ↓
              Discover 10.1.1.9
                      ↓
           Scan ports on 10.1.1.9
                      ↓
        Find web app on port 9999
                      ↓
          Exploit vulnerability
                      ↓
       Exfiltrate SSH private key
                      ↓
       SSH to 10.1.1.9 as webmaster
                      ↓
            Read /etc/flag_*.txt
                      ↓
                  🏁 FLAG!
```

## Static IP Configuration

Both VMs use the `debian-ip-setter` package from Deputy Digital Library to configure static IP addresses.

### Kali Linux Configuration
```yaml
features:
  kali-static-ip:
    type: service
    source: debian-ip-setter
    environment:
      - STATIC_IP=10.1.1.10/30
```

### Target Server Configuration
```yaml
features:
  server-static-ip:
    type: service
    source: debian-ip-setter
    environment:
      - STATIC_IP=10.1.1.9/30
```

## Testing Network Configuration

### From Kali Linux

Check IP configuration:
```bash
ip addr show
# Should show 10.1.1.10/30
```

Verify connectivity to target:
```bash
ping 10.1.1.9
```

Scan target:
```bash
nmap -p- 10.1.1.9
```

### Expected nmap Results
```
PORT     STATE SERVICE
22/tcp   open  ssh
9999/tcp open  unknown
```

## Troubleshooting

### VMs Can't Communicate
- Check that both VMs have correct IP addresses
- Verify `debian-ip-setter` feature is applied
- Check switch configuration

### Participant Can't Access Kali
- Verify Kali SSH service is running
- Check external network routing
- Verify kali/kali credentials

### Can't Reach Target from Kali
- Ping 10.1.1.9 from Kali
- Check target VM services are running
- Verify firewall rules not blocking traffic
