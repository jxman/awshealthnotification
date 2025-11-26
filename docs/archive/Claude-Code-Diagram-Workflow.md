# Claude Code Workflow: AWS Architecture Diagram Generation

A step-by-step guide for using Claude Code to generate professional AWS architecture diagrams from Terraform projects.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Asset Setup](#asset-setup)
- [Claude Code Setup](#claude-code-setup)
- [Workflow Steps](#workflow-steps)
- [Claude Prompts](#claude-prompts)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

This workflow leverages Claude Code's ability to analyze Terraform configurations and generate professional AWS architecture diagrams using official AWS service icons. The process is reproducible across multiple projects and maintains consistency with AWS documentation standards.

### What You'll Get

- Professional SVG diagrams with official AWS icons
- Proper service relationships and data flows
- Multi-environment support visualization
- Reusable workflow for all Terraform projects

## Prerequisites

### Required Tools

- **Claude Code** (latest version)
- **Terraform project** with AWS resources
- **AWS Architecture Icons** (official asset package)
- **SVG viewer** (browser or dedicated tool)

### Supported Terraform Patterns

- Module-based architecture
- Multi-environment setups (dev/prod/staging)
- AWS provider configurations
- Standard Terraform file structure

## Asset Setup

### Step 1: Download Official AWS Icons

1. **Visit AWS Architecture Center**
   ```
   https://aws.amazon.com/architecture/icons/
   ```

2. **Download Asset Package**
   - Click "Download AWS Architecture Icons"
   - Save to a local directory (e.g., `~/Downloads/`)
   - Extract the ZIP file

3. **Verify Asset Structure**
   ```
   Asset-Package_[DATE]/
   ├── Architecture-Service-Icons_[DATE]/
   │   ├── Arch_App-Integration/
   │   ├── Arch_Compute/
   │   ├── Arch_Database/
   │   ├── Arch_Management-Governance/
   │   ├── Arch_Security-Identity-Compliance/
   │   ├── Arch_Storage/
   │   └── ...
   └── Category-Icons_[DATE]/
   ```

### Step 2: Organize Icons by Size

The asset package contains multiple sizes. For diagrams, use **64px SVG versions**:

```
Architecture-Service-Icons_[DATE]/
├── Arch_Compute/64/Arch_AWS-Lambda_64.svg
├── Arch_App-Integration/64/Arch_Amazon-EventBridge_64.svg
├── Arch_App-Integration/64/Arch_Amazon-Simple-Notification-Service_64.svg
├── Arch_Storage/64/Arch_Amazon-Simple-Storage-Service_64.svg
├── Arch_Management-Governance/64/Arch_Amazon-CloudWatch_64.svg
└── ...
```

## Claude Code Setup

### Initial Project Analysis

1. **Open Claude Code** in your Terraform project directory
2. **Verify Project Structure**
   ```bash
   ls -la
   # Should show: main.tf, modules/, environments/, etc.
   ```

3. **Ensure Clean Git Status**
   ```bash
   git status
   # Should be clean or have expected changes
   ```

## Workflow Steps

### Step 1: Project Discovery

**Prompt:**
```
I need to create an AWS architecture diagram for this Terraform project. Can you:

1. Analyze the Terraform configuration files
2. Identify all AWS services being used
3. Map out the relationships between services
4. List the environments configured (dev/prod/staging)

Please examine:
- Main configuration files in environments/
- Module definitions in modules/
- Any backend configurations
- Resource dependencies and data flows
```

### Step 2: Icon Asset Integration

**Prompt:**
```
I have the official AWS Architecture Icons downloaded to:
'[PATH_TO_ASSET_PACKAGE]'

Can you:

1. Search through the asset package and find the specific SVG icons for each AWS service we identified
2. Provide the exact file paths for the 64px SVG versions
3. List the services we need icons for and their corresponding files

For example, if we're using Lambda, find:
'Arch_Compute/64/Arch_AWS-Lambda_64.svg'
```

### Step 3: Diagram Generation

**Prompt:**
```
Now create a professional AWS architecture diagram using the official AWS service icons. Requirements:

1. Use the SVG icons from the asset package (embed the SVG content directly)
2. Show clear data flow with arrows between services
3. Position icons properly with service labels below
4. Use official AWS colors from the icons
5. Include environment indicators (dev/prod)
6. Make the diagram production-ready and professional

Create an SVG file with:
- 1400x900 canvas size
- Proper icon scaling (0.7 scale factor works well)
- Clear service labels and descriptions
- Data flow arrows with labels
- Environment badges
- Professional spacing and alignment

The diagram should look like official AWS architecture diagrams.
```

### Step 4: Refinement and Validation

**Prompt:**
```
Please review the generated diagram and fix any issues with:

1. Icon and text positioning (prevent overlaps)
2. Arrow alignment with updated service positions
3. Consistent spacing and professional appearance
4. Proper SVG syntax and validation

Make sure:
- Icons are centered in their service boxes
- Text appears below icons with proper spacing
- Arrows connect accurately between services
- The overall layout is clean and readable
```

## Claude Prompts

### Complete Workflow Prompt

For experienced users, use this comprehensive prompt:

```
I need to create a professional AWS architecture diagram from my Terraform project. Please follow this workflow:

## Phase 1: Analysis
1. Examine all Terraform files (main.tf, modules/, environments/)
2. Identify AWS services, their relationships, and data flows
3. Detect multi-environment setup

## Phase 2: Asset Integration
1. Use the AWS asset package at: '[YOUR_ASSET_PATH]'
2. Find the 64px SVG icons for each identified service
3. Extract SVG content for embedding

## Phase 3: Diagram Creation
1. Create a professional SVG diagram (1400x900)
2. Use official AWS icons with 0.7 scale factor
3. Position icons at top-center of service boxes
4. Place service labels below icons
5. Add data flow arrows with labels
6. Include environment badges
7. Use official AWS colors and styling

## Requirements:
- Professional appearance matching AWS standards
- Clear service relationships and data flows
- Proper icon positioning and text alignment
- No overlapping elements
- Consistent spacing throughout

Generate a complete, production-ready architecture diagram.
```

### Troubleshooting Prompts

**For Icon Issues:**
```
The icons in the diagram are not displaying correctly. Please:

1. Check the SVG syntax for any errors
2. Verify the icon paths are embedded properly
3. Ensure the scaling and positioning are correct
4. Fix any overlapping text or icons

Use the format:
- Icons centered at translate(centerX, 10) scale(0.7)
- Text positioned at y=95 and y=115 for labels
- Service boxes sized appropriately for content
```

**For Layout Issues:**
```
The diagram layout needs improvement. Please:

1. Adjust service box positions to prevent crowding
2. Update arrow paths to align with new positions
3. Ensure consistent spacing between elements
4. Maintain professional appearance

Follow AWS architecture diagram standards for spacing and alignment.
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: Icons Not Displaying

**Problem:** SVG icons appear as broken or missing
**Solution:**
```
1. Verify the asset package path is correct
2. Check that SVG content is properly embedded
3. Ensure no syntax errors in the SVG structure
4. Validate the icon paths in the asset package
```

#### Issue: Text Overlapping Icons

**Problem:** Service labels appear on top of icons
**Solution:**
```
1. Adjust icon position to top of service box
2. Move text labels below icons (y=95, y=115)
3. Increase service box height if needed
4. Use proper transform positioning
```

#### Issue: Arrows Misaligned

**Problem:** Data flow arrows don't connect properly
**Solution:**
```
1. Update arrow coordinates after repositioning services
2. Account for new service box positions
3. Ensure arrows point to service centers
4. Add proper arrow markers
```

### Asset Package Issues

#### Missing Icons

If specific service icons are not found:

1. **Check Alternative Names:**
   ```
   # Lambda might be:
   - Arch_AWS-Lambda_64.svg
   - Arch_Lambda_64.svg

   # SNS might be:
   - Arch_Amazon-Simple-Notification-Service_64.svg
   - Arch_SNS_64.svg
   ```

2. **Search by Category:**
   ```bash
   find . -name "*Lambda*" -type f
   find . -name "*SNS*" -type f
   find . -name "*EventBridge*" -type f
   ```

3. **Use Generic Icons:**
   - For missing services, use category icons
   - Compute, Storage, Database, etc.

## Best Practices

### Project Organization

1. **Keep Assets Accessible**
   ```
   ~/AWS-Assets/
   ├── Architecture-Service-Icons/
   └── Category-Icons/
   ```

2. **Document Your Workflow**
   - Save successful prompts
   - Note any project-specific adjustments
   - Keep icon mappings for reference

### Diagram Quality

1. **Consistency Across Projects**
   - Use same canvas size (1400x900)
   - Maintain icon scaling (0.7)
   - Follow AWS color schemes

2. **Professional Standards**
   - Include environment indicators
   - Show clear data flows
   - Add descriptive labels
   - Maintain proper spacing

### Claude Code Efficiency

1. **Batch Operations**
   - Analyze all files in one request
   - Generate complete diagrams in single sessions
   - Make refinements iteratively

2. **Clear Instructions**
   - Specify exact asset paths
   - Include size and positioning requirements
   - Request validation and error checking

### Reusability

1. **Template Approach**
   - Save working SVG templates
   - Document icon mappings
   - Create reusable prompt sets

2. **Version Control**
   - Commit generated diagrams
   - Track changes with infrastructure
   - Include in documentation

## Example Project Types

### Microservices Architecture

**Services Typically Involved:**
- API Gateway, Lambda, DynamoDB
- SNS/SQS for messaging
- CloudWatch for monitoring

**Diagram Focus:**
- Request flow from API to backend
- Inter-service communication
- Data persistence patterns

### Data Pipeline

**Services Typically Involved:**
- S3, Lambda, Kinesis
- Glue, Athena, QuickSight
- CloudWatch for monitoring

**Diagram Focus:**
- Data ingestion flow
- Processing stages
- Output destinations

### Web Application

**Services Typically Involved:**
- CloudFront, ALB, EC2/ECS
- RDS, ElastiCache
- IAM, CloudWatch

**Diagram Focus:**
- User request flow
- Application tiers
- Database connections

## Integration with Documentation

### README Integration

Add diagrams to your project README:

```markdown
## Architecture

![AWS Architecture](./architecture-diagram.svg)

### Components

- **EventBridge**: Routes AWS Health events
- **Lambda**: Processes and formats notifications
- **SNS**: Distributes notifications to subscribers
```

### Documentation Sites

For wikis or documentation sites:

```markdown
# Architecture Overview

<img src="architecture-diagram.svg" alt="AWS Architecture" width="100%">

## Data Flow

1. AWS Health events trigger EventBridge rules
2. Lambda function processes and formats events
3. SNS distributes notifications to subscribers
```

This workflow provides a complete, reproducible process for generating professional AWS architecture diagrams using Claude Code and official AWS assets.
