# Restic Backup Performance Optimization

## Why First Backup is Slow
Restic's first backup is naturally slow because it must:
- Hash and deduplicate ALL files in the system
- Encrypt every single file chunk
- Compress data
- Transfer everything to remote repository

## Optimization Options

### 1. Use Faster Encryption
Replace ChaCha20 with AES-256-GCM (hardware accelerated on Intel/AMD):
```bash
restic init --repo-type rest --password-file /path/to/passwd \
  --crypt-key aes-256-gcm \
  ssh://usdaw@srvdocker02/~/ubuntu58-backup
```

### 2. Reduce or Disable Compression
Restic's default compression can be CPU-intensive. Options:
- `none`: No compression (fastest)
- `auto`: Adaptive compression
- `max`: Maximum compression (slowest)

### 3. Increase Worker Threads
Add `--limit-upload` and `--max-concurrent-uploads` flags:
```bash
restic backup / \
  --repo ssh://usdaw@srvdocker02/~/ubuntu58-backup \
  --repo-file /path/to/password \
  --compression auto \
  --tag full-system \
  --max-concurrent-uploads 8 \
  --limit-upload 0
```

### 4. Exclude More Directories
Add exclusions for temporary/cache directories:
```bash
--exclude='/proc' \
--exclude='/sys' \
--exclude='/dev' \
--exclude='/tmp' \
--exclude='/var/cache' \
--exclude='/var/tmp' \
--exclude='/var/log/journal' \
--exclude='/home/*/.cache' \
--exclude='/home/*/.local/share/Trash' \
--exclude='/home/*/.mozilla/firefox/*/cache' \
--exclude='/home/*/.cache' \
--exclude='/root/.cache'
```

### 5. Check Repository Performance
Test if remote server is bottleneck:
```bash
# Test repository initialization speed
time restic init --repo ssh://usdaw@srvdocker02/~/ubuntu58-backup-test

# Test small backup
time restic backup /home --repo ssh://usdaw@srvdocker02/~/ubuntu58-backup-test
```

### 6. Monitor Resource Usage
On the VM, check:
```bash
# CPU usage
top -p $(pgrep restic)

# Memory usage
free -h

# Network usage
iftop -i eth0
```

### 7. Network Optimization
```bash
# Use SSH compression (add to ~/.ssh/config)
Host srvdocker02
  Compression yes
  CompressionLevel 6
```

### 8. Repository Structure Optimization
For better performance, initialize repository with:
```bash
restic init --repo-type rest \
  --password-file /path/to/passwd \
  --crypt-key aes-256-gcm \
  --compression auto \
  ssh://usdaw@srvdocker02/~/ubuntu58-backup
```

## Expected Performance Improvements
- AES-256-GCM: 30-50% faster on modern CPUs
- No compression: 20-40% faster
- Better exclusions: 10-30% fewer files to process
- SSH compression: 10-20% faster network transfer

## Recommendations for Your Case
Since this is the first backup and you're on LAN:
1. Use AES-256-GCM encryption
2. Set compression to `auto` or `none`
3. Add more exclusions
4. Monitor resource usage to identify bottlenecks
5. Consider running backup during off-hours if performance impact is noticeable