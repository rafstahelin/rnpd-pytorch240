# RAF RunPod PyTorch Template
Version: 3.3 (Stable) / 3.4 (Development)  
Status: Active Development

## Overview
Custom PyTorch Docker template for RunPod with integrated file-scripts support and advanced machine learning capabilities.

## Features
### Current Stable (v3.3)
- Base: PyTorch 2.4.0, Python 3.11, CUDA 12.4.1
- Integrated Services:
  - Jupyter Lab (Port 8888)
  - SSH Server (Port 22)
  - Nginx Proxy (Port 80)
  - File-Scripts Auto-Installation

### Coming in v3.4
- HuggingFace Integration
- Weights & Biases Support
- Rclone/Dropbox Synchronization

## Quick Start
```bash
# Pull the stable image
docker pull rafrafraf/rnpd-pytorch240:latest

# Run locally
docker run -p 8888:8888 -p 22:22 -p 80:80 \
  -v /path/to/workspace:/workspace \
  rafrafraf/rnpd-pytorch240:latest

# Access points
- Jupyter: http://localhost:8888 (password: 1234)
- SSH: ssh -p 22 root@localhost (password: 1234)
```

## Workspace Structure
```bash
/workspace/
├── file-scripts/     # Auto-installed tools
├── SimpleTuner/      # ML workspace
│   ├── config/      # Training configurations
│   ├── datasets/    # Training data
│   └── output/      # Training results
└── StableSwarmUI/    # Model management
```

## RunPod Deployment
1. Template: `rafrafraf/rnpd-pytorch240:latest`
2. Environment Variables:
   - JUPYTER_PASSWORD: Custom password (default: 1234)
   - SSH_PORT: 22 (fixed)
   - JUPYTER_PORT: 8888 (fixed)
3. Volume Configuration:
   - Mount point: /workspace
   - Network volume recommended

## Development
For detailed setup instructions and guides, see:
- [Development Guide](docs/development/README.md)
- [Deployment Guide](docs/deployment/README.md)
- [Version History](docs/versions/README.md)

## Container Services
- Jupyter Lab with terminal support
- SSH access for remote development
- Nginx reverse proxy
- Automatic workspace setup
- File-scripts integration

## Version History
- v3.3: Current stable with basic integrations
- v3.4: Development version with enhanced ML support
  - v3.4.1: HuggingFace integration
  - v3.4.2: Weights & Biases integration
  - v3.4.3: Rclone/Dropbox integration

## Contributing
1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'feat: Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Support
For issues and feature requests, please use the GitHub issue tracker.
