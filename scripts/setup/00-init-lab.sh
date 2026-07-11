#!/bin/bash
# ~/k8s-lab/scripts/setup/00-init-lab.sh

# Run this on your laptop first, then on each node

# Create structure
mkdir -p ~/k8s-lab/{scripts/{setup,management,monitoring,utils},manifests/{ingress,storage,apps},configs,docs}

# Clone git repo (if exists)
if [ ! -d ~/k8s-lab/.git ]; then
    cd ~/k8s-lab
    git init
    echo "Initialized git repository"
fi

# Create .gitignore
cat > ~/k8s-lab/.gitignore << 'EOF'
*.swp
*.tmp
*.log
.env
kubeconfig
secrets/
EOF

# Set permissions
chmod +x ~/k8s-lab/scripts/**/*.sh 2>/dev/null || true

echo "Lab structure created at ~/k8s-lab"