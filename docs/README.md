# Documentation Directory

This directory contains project documentation, architecture diagrams, and archived historical documents.

## Structure

```
docs/
├── architecture/     # AWS architecture diagrams (SVG files)
├── archive/          # Historical documentation and planning documents
└── README.md         # This file
```

## Architecture Diagrams

The `architecture/` directory contains AWS architecture diagrams generated from the Terraform infrastructure:

- **aws-architecture-diagram.svg** - Basic architecture diagram
- **aws-architecture-diagram-with-icons.svg** - Diagram with AWS service icons
- **aws-architecture-official-icons.svg** - Official AWS icons version

These diagrams are referenced in the main [README.md](../README.md) and provide visual documentation of the infrastructure.

## Archive

The `archive/` directory contains historical documentation that may be useful for reference but is not actively maintained:

- **AWS-Architecture-Diagram-Generator.md** - General guide for generating AWS diagrams
- **Claude-Code-Diagram-Workflow.md** - Workflow documentation for diagram generation
- **DEPLOY_ENHANCEMENTS.md** - Historical documentation of deploy.sh improvements
- **SCRIPT_ORGANIZATION_PLAN.md** - Planning document for script organization
- **organize-scripts.sh** - One-time script organization tool
- **preview-organization.sh** - Organization preview tool

## Project Documentation

For active project documentation, see:

- [Main README](../README.md) - Project overview and usage
- [Deployment Guide](../deployment.md) - Deployment instructions
- [CLAUDE.md](../CLAUDE.md) - Project-specific Claude Code instructions
