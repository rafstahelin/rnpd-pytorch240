# RAF RunPod PyTorch Template
Version: 4.0.0 (Stable)
Status: Production Ready

## Overview
Custom PyTorch Docker template for RunPod optimized for machine learning workloads with integrated HuggingFace and Rclone support.

## Features
### Current Stable (v4.0.0)
- Base: PyTorch 2.4.0, Python 3.11, CUDA 12.4.1
- Integrated Services:
  - Jupyter Lab (Port 8888)
  - SSH Server (Port 22)
  - Nginx Proxy (Port 80)
- ML Integration:
  - HuggingFace with token support
  - Rclone/Dropbox synchronization
  - Network volume optimization
  - wandb DISABLED

## Quick Start
```bash
# Pull the stable image
docker pull rafrafraf/rnpd-pytorch240:latest

# Run locally
docker run -p 8888:8888 -p 22:22 -p 80:80 \
  -v /path/to/workspace:/workspace \
  -e HF_TOKEN=your_token \
  rafrafraf/rnpd-pytorch240:latest

# Access points
- Jupyter: http://localhost:8888 (password: 1234)
- SSH: ssh -p 22 root@localhost (password: 1234)
```

## Workspace Structure
```bash
/workspace/
├── .cache/
│   └── huggingface/    # HF cache directory
├── .config/
│   └── rclone/        # Rclone configuration
├── SimpleTuner/       # ML workspace
│   ├── config/       # Training configurations
│   ├── datasets/     # Training data
│   └── output/       # Training results
└── StableSwarmUI/     # Model management
```

## RunPod Deployment
1. Template: `rafrafraf/rnpd-pytorch240:latest`
2. Environment Variables:
   - JUPYTER_PASSWORD: Custom password (default: 1234)
   - HF_TOKEN: Your HuggingFace token
   - SSH_PORT: 22 (fixed)
   - JUPYTER_PORT: 8888 (fixed)
3. Volume Configuration:
   - Mount point: /workspace
   - Network volume required for persistence

## Integration Features

### HuggingFace
- Automatic token configuration
- Persistent cache directory
- Model and dataset management
- Token verification via `huggingface_hub.HfApi().whoami()`

### Rclone
- Network volume configuration
- Dropbox synchronization support
- Automatic configuration loading
- Persistent settings

## Container Services
- Jupyter Lab with terminal support
- SSH access for remote development
- Nginx reverse proxy
- Automatic workspace setup
- Network volume optimization

## Version History
- v4.0.0: Current stable
  - Working HuggingFace integration
  - Working Rclone/Dropbox support
  - Network volume optimization
  - Removed file-scripts dependency

## Development
For custom development:
1. Fork the repository
2. Local testing:
```bash
docker build -t mytest:latest .
docker run -p 8888:8888 -v /path/to/workspace:/workspace mytest:latest
```

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
