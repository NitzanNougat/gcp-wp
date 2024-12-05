# WordPress on GCP with Terraform

This project deploys a highly available WordPress installation on Google Cloud Platform (GCP) using Terraform. The setup includes GKE for container orchestration, Cloud SQL for database management, and comprehensive monitoring.

## Architecture

![Architecture Diagram](architecture-diagram.png)

The infrastructure consists of:
- GKE cluster for WordPress hosting
- Cloud SQL (MySQL) with private networking
- NFS server for persistent storage
- Load balancer with global IP
- Comprehensive monitoring and logging

## Prerequisites

- GCP Project with required APIs enabled
- Terraform v1.9.8
- GitHub account for CI/CD
- GCS bucket for Terraform state

## Quick Start

1. Fork this repository
2. Configure GitHub Secrets:
   ```
   GCP_CREDENTIALS
   TF_VAR_project_id
   TF_VAR_region
   TF_VAR_alert_email
   ```

3. Push to main branch to trigger deployment

## Features

- **High Availability**: Multiple WordPress pods with auto-scaling
- **Security**: Private networking and managed SSL certificates
- **Monitoring**: Cloud Monitoring with email alerts
- **CI/CD**: Automated deployment via GitHub Actions
- **State Management**: Remote state in GCS with locking

## Project Structure

```
├── modules/
│   ├── gcp/         # GCP infrastructure
│   ├── k8s/         # Kubernetes resources
│   └── monitoring/  # Monitoring configuration
├── .github/
│   └── workflows/   # GitHub Actions
└── *.tf            # Root module configuration
```

## Contributing

1. Create a feature branch
2. Make changes
3. Submit a pull request

## License

MIT

## Support

Open an issue in the repository for any questions or problems.