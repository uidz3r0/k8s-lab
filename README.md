# AJ's Kubernetes Home Lab 

## Quick Start on Your Laptop

```bash
# On your main laptop (control)
cd ~
mkdir -p k8s-lab
cd k8s-lab

# Initialize with my structure
curl -s https://gist.github.com/your-gist-url/setup-lab.sh | bash

# Or create manually
mkdir -p scripts/{setup,management,monitoring,utils}
mkdir -p manifests/{ingress,storage,apps}
mkdir -p configs docs

# Create your first script
cat > scripts/setup/01-node-setup.sh << 'EOF'
#!/bin/bash
echo "Node setup script..."
EOF
chmod +x scripts/setup/*.sh

# Sync to all nodes
for node in luke han leia; do
    rsync -avz ~/k8s-lab/ $node@10.1.1.10:~/k8s-lab/ 2>/dev/null || true
done
```

---

## Security Tips

1. Never store secrets in scripts - Use environment variables or Vault
2. Add .gitignore for sensitive files
3. Use `set -e` in scripts to fail fast
4. Log outputs - `script.sh 2>&1 | tee script.log`
5. Backup your scripts to **GitHub/GitLab**