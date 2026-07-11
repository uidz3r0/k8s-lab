#!/bin/bash
# Source this in your .bashrc or .zshrc

alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kx='kubectl exec -it'
alias ka='kubectl apply -f'
alias kd='kubectl delete -f'

# Namespace shortcuts
alias kgpa='kubectl get pods --all-namespaces'
alias kgsa='kubectl get svc --all-namespaces'

# Context switching
alias kctx='kubectl config current-context'
alias kuse='kubectl config use-context'

# Watch resources
alias kgpw='kubectl get pods -w'
alias kgsw='kubectl get svc -w'

# Describe node
alias kdn='kubectl describe node'