#!/bin/bash

# AWS Health Notification - Enhanced Deployment Script
# This script follows Terraform deployment best practices for safety and reliability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_VERSION_MIN="1.0.0"
PLAN_FILE="deployment.tfplan"
LOG_DIR="logs"
LOG_FILE=""

# Function to extract value from HCL file - FIXED VERSION
extract_hcl_value() {
    local file="$1"
    local key="$2"

    if [ ! -f "$file" ]; then
        echo ""
        return
    fi

    # Use awk for more reliable parsing (same as validate-backend.sh)
    awk -F= -v key="$key" '
        $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
            gsub(/^[[:space:]]*[^=]*=[[:space:]]*"?/, "", $0)
            gsub(/"?[[:space:]]*$/, "", $0)
            print $0
            exit
        }
    ' "$file"
}

# Function to setup logging - FIXED VERSION
setup_logging() {
    local env=$1

    # Create logs directory if it doesn't exist
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        echo "Created logs directory: $LOG_DIR"
    fi

    # Set log file path in logs directory
    LOG_FILE="$LOG_DIR/deployment-${env}-$(date +%Y%m%d-%H%M%S).log"

    # Create log file and add header
    cat > "$LOG_FILE" << EOF
# AWS Health Notification Deployment Log
# Environment: $env
# Timestamp: $(date)
# User: $(whoami)
# AWS Account: $(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
# =================================================================

EOF

    # Ensure log file is writable
    if [ ! -w "$LOG_FILE" ]; then
        echo "Error: Cannot write to log file: $LOG_FILE"
        exit 1
    fi
}

# Function to log messages with timestamp - FIXED VERSION
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        "INFO")  echo -e "${BLUE}[INFO] ${timestamp}:${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN] ${timestamp}:${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR] ${timestamp}:${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS] ${timestamp}:${NC} $message" ;;
    esac

    # Also log to file if LOG_FILE is set and writable
    if [ -n "$LOG_FILE" ] && [ -w "$LOG_FILE" ]; then
        echo "[$level] $timestamp: $message" >> "$LOG_FILE"
    elif [ -n "$LOG_FILE" ]; then
        # If log file is set but not writable, try to create the directory and file
        mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
        echo "[$level] $timestamp: $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Function to handle errors with cleanup
handle_error() {
    log_message "ERROR" "$1"

    # Cleanup plan file if it exists
    if [ -f "$PLAN_FILE" ]; then
        rm -f "$PLAN_FILE"
        log_message "INFO" "Cleaned up plan file: $PLAN_FILE"
    fi

    echo ""
    echo -e "${RED}🚨 Deployment failed!${NC}"
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  1. Check AWS credentials: aws sts get-caller-identity"
    echo "  2. Verify S3 bucket access: aws s3 ls s3://your-bucket"
    echo "  3. Validate backend config: ./validate-backend.sh"
    echo "  4. Check Terraform syntax: terraform validate"
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        echo "  5. Review deployment log: $LOG_FILE"
    fi

    exit 1
}

# Function to check prerequisites
check_prerequisites() {
    log_message "INFO" "Checking prerequisites..."

    # Check if required tools are installed
    local tools=("terraform" "aws" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            handle_error "$tool is not installed or not in PATH"
        fi
    done

    # Check Terraform version
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    log_message "INFO" "Terraform version: $tf_version"

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        handle_error "AWS credentials not configured or invalid"
    fi

    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_user=$(aws sts get-caller-identity --query Arn --output text)
    log_message "INFO" "AWS Account: $aws_account"
    log_message "INFO" "AWS Identity: $aws_user"

    log_message "SUCCESS" "All prerequisites met"
}

# Function to validate environment
validate_environment() {
    local env=$1

    log_message "INFO" "Validating environment: $env"

    # Validate environment name
    if [[ "$env" != "dev" && "$env" != "prod" && "$env" != "staging" ]]; then
        handle_error "Invalid environment '$env'. Allowed: dev, prod, staging"
    fi

    # Check if environment directory exists
    local env_dir="environments/$env"
    if [ ! -d "$env_dir" ]; then
        handle_error "Environment directory '$env_dir' not found"
    fi

    # Check required files
    local required_files=("$env_dir/main.tf" "$env_dir/variables.tf" "$env_dir/terraform.tfvars")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            handle_error "Required file not found: $file"
        fi
    done

    # Check backend configuration
    local backend_config="backend/$env.hcl"
    if [ ! -f "$backend_config" ]; then
        handle_error "Backend configuration not found: $backend_config"
    fi

    # Validate backend configuration values using improved parsing
    if [ -z "$(extract_hcl_value "$backend_config" "bucket")" ]; then
        handle_error "Backend configuration missing or invalid bucket parameter"
    fi

    log_message "SUCCESS" "Environment validation passed"
}

# Function to check S3 backend access
check_backend_access() {
    local env=$1
    local backend_config="backend/$env.hcl"

    log_message "INFO" "Checking S3 backend access..."

    # Extract bucket name using improved parsing
    local bucket=$(extract_hcl_value "$backend_config" "bucket")

    if [ -z "$bucket" ]; then
        handle_error "Could not extract bucket name from backend configuration"
    fi

    log_message "INFO" "Testing access to S3 bucket: $bucket"

    # Test S3 bucket access
    if ! aws s3 ls "s3://$bucket" &> /dev/null; then
        handle_error "Cannot access S3 bucket: $bucket. Check permissions and bucket existence."
    fi

    log_message "SUCCESS" "S3 backend accessible: $bucket"
}

# Function to perform pre-deployment checks
pre_deployment_checks() {
    local env=$1
    local env_dir="environments/$env"

    log_message "INFO" "Performing pre-deployment checks..."

    cd "$env_dir" || handle_error "Failed to change to environment directory"

    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        log_message "INFO" "Initializing Terraform..."
        terraform init -backend-config="../../backend/$env.hcl" || handle_error "Terraform initialization failed"
    else
        log_message "INFO" "Terraform already initialized"
    fi

    # Validate Terraform configuration
    log_message "INFO" "Validating Terraform configuration..."
    terraform validate || handle_error "Terraform validation failed"

    # Check for potential issues
    log_message "INFO" "Checking for configuration drift..."
    if terraform plan -detailed-exitcode -out=/dev/null &> /dev/null; then
        log_message "INFO" "No configuration drift detected"
    else
        local exit_code=$?
        if [ $exit_code -eq 2 ]; then
            log_message "WARN" "Configuration drift detected - changes are needed"
        else
            handle_error "Error checking for drift (exit code: $exit_code)"
        fi
    fi

    log_message "SUCCESS" "Pre-deployment checks passed"
}

# Function to create deployment plan
create_plan() {
    local env=$1

    log_message "INFO" "Creating deployment plan..."

    # Remove old plan file if it exists
    if [ -f "$PLAN_FILE" ]; then
        rm -f "$PLAN_FILE"
    fi

    # Create plan with detailed output
    if terraform plan -var-file="terraform.tfvars" -out="$PLAN_FILE" -detailed-exitcode; then
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            log_message "INFO" "No changes needed - infrastructure is up to date"
            return 0
        elif [ $exit_code -eq 2 ]; then
            log_message "INFO" "Changes detected - plan created successfully"
            return 2
        fi
    else
        handle_error "Failed to create deployment plan"
    fi
}

# Function to display plan summary
show_plan_summary() {
    log_message "INFO" "Deployment Plan Summary:"
    echo ""

    # Use terraform show to display the plan in a readable format
    terraform show "$PLAN_FILE" | head -50

    echo ""
    echo -e "${YELLOW}💡 Full plan details available above${NC}"
    echo ""
}

# Function to get user confirmation for deployment
get_deployment_confirmation() {
    local env=$1

    echo -e "${YELLOW}⚠️  Deployment Confirmation${NC}"
    echo "================================"
    echo "  Environment: $env"
    echo "  Plan file: $PLAN_FILE"
    if [ -n "$LOG_FILE" ]; then
        echo "  Log file: $LOG_FILE"
    fi
    echo "  Timestamp: $(date)"
    echo ""

    # Extra confirmation for production
    if [ "$env" = "prod" ]; then
        echo -e "${RED}🚨 PRODUCTION DEPLOYMENT WARNING${NC}"
        echo "You are about to deploy to PRODUCTION environment!"
        echo ""
        read -p "$(echo -e ${RED}Type 'DEPLOY-PROD' to confirm production deployment: ${NC})" -r
        if [ "$REPLY" != "DEPLOY-PROD" ]; then
            log_message "INFO" "Production deployment cancelled by user"
            rm -f "$PLAN_FILE"
            exit 0
        fi
        echo ""
    fi

    read -p "$(echo -e ${BLUE}Do you want to apply these changes? [y/N]: ${NC})" -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "INFO" "Deployment cancelled by user"
        rm -f "$PLAN_FILE"
        exit 0
    fi
}

# Function to apply the deployment
apply_deployment() {
    local env=$1

    log_message "INFO" "Starting deployment..."

    local start_time=$(date +%s)

    # Apply the plan
    if terraform apply "$PLAN_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        log_message "SUCCESS" "Deployment completed successfully in ${duration}s"

        # Clean up plan file
        rm -f "$PLAN_FILE"

        # Show outputs
        log_message "INFO" "Deployment outputs:"
        terraform output || log_message "WARN" "No outputs defined or error getting outputs"

    else
        handle_error "Deployment failed during terraform apply"
    fi
}

# Function to run post-deployment validation
post_deployment_validation() {
    local env=$1

    log_message "INFO" "Running post-deployment validation..."

    # Verify deployment state
    if terraform plan -detailed-exitcode &> /dev/null; then
        log_message "SUCCESS" "Post-deployment validation: No drift detected"
    else
        log_message "WARN" "Post-deployment validation: Configuration drift detected"
    fi

    # Check if key resources exist (customize based on your resources)
    log_message "INFO" "Validating key resources..."

    # Example: Check if SNS topic exists
    local sns_topic_arn=$(terraform output -json 2>/dev/null | jq -r '.sns_topic_arn.value // empty')
    if [ -n "$sns_topic_arn" ]; then
        if aws sns get-topic-attributes --topic-arn "$sns_topic_arn" &> /dev/null; then
            log_message "SUCCESS" "SNS topic validation passed"
        else
            log_message "WARN" "SNS topic validation failed"
        fi
    fi

    log_message "SUCCESS" "Post-deployment validation completed"
}

# Main deployment function
main() {
    local env=$1

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🚀 AWS Health Notification Deployment              ║${NC}"
    echo -e "${CYAN}║                     Enhanced Deployment Script                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Set up logging first, before any log_message calls
    setup_logging "$env"

    log_message "INFO" "Starting deployment process for environment: $env"
    log_message "INFO" "Log file: $LOG_FILE"

    # Run all checks and deployment steps
    check_prerequisites
    validate_environment "$env"
    check_backend_access "$env"
    pre_deployment_checks "$env"

    # Create and review plan
    local plan_exit_code
    create_plan "$env"
    plan_exit_code=$?

    if [ $plan_exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ No changes needed - infrastructure is up to date!${NC}"
        rm -f "$PLAN_FILE"
        log_message "INFO" "Deployment completed - no changes needed"
        exit 0
    fi

    # Show plan and get confirmation
    show_plan_summary
    get_deployment_confirmation "$env"

    # Apply deployment
    apply_deployment "$env"

    # Post-deployment validation
    post_deployment_validation "$env"

    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "  • Test the deployment: ./test-health-notification.sh $env"
    echo "  • Monitor CloudWatch logs for any issues"
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        echo "  • Review deployment log: $LOG_FILE"
    fi
    echo ""
    log_message "SUCCESS" "Deployment process completed"
}

# Script entry point
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Environment not specified${NC}"
    echo ""
    echo "Usage: ./deploy.sh <environment>"
    echo ""
    echo "Available environments:"
    echo "  • dev      - Development environment"
    echo "  • prod     - Production environment"
    echo "  • staging  - Staging environment (if configured)"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh dev    # Deploy to development"
    echo "  ./deploy.sh prod   # Deploy to production"
    echo ""
    echo "💡 Tip: Run './validate-backend.sh' first to ensure configuration is correct"
    exit 1
fi

# Run main deployment process
main "$1"
