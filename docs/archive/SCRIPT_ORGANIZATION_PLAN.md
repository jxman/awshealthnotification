# 📁 Terraform Project Script Organization Plan

## 🎯 **Proposed Structure:**

```
📦 awshealthnotification/
├── 🔧 Core Scripts (Root Level - Easy Access)
│   ├── init.sh                    # Environment initialization
│   ├── deploy.sh                  # Main deployment script
│   └── validate-backend.sh        # Configuration validation
│
├── 📁 scripts/                    # Organized script directory
│   ├── 📁 testing/               # All testing scripts
│   │   ├── test-health-notification.sh
│   │   ├── test-lambda-formatter.sh
│   │   ├── test-deploy.sh
│   │   └── test-init.sh
│   │
│   ├── 📁 utilities/             # Utility and management scripts
│   │   ├── setup-summary.sh
│   │   ├── manage-logs.sh
│   │   ├── cleanup-project.sh
│   │   └── quick-cleanup.sh
│   │
│   ├── 📁 legacy/                # Backup and legacy scripts
│   │   └── deploy-simple.sh
│   │
│   └── 📄 README.md              # Script documentation
│
└── 📁 logs/                      # Deployment logs (already organized)
    ├── 📄 README.md
    └── 📄 deployment-*.log
```

## ✅ **Benefits of This Structure:**

### **🚀 Easy Access to Essentials**
- Core scripts (`init.sh`, `deploy.sh`, `validate-backend.sh`) stay in root
- No disruption to existing workflows
- Quick access to most-used scripts

### **📂 Logical Grouping**
- **Testing scripts** → `scripts/testing/`
- **Utility scripts** → `scripts/utilities/`  
- **Legacy scripts** → `scripts/legacy/`

### **🧹 Clean Root Directory**
- Root only contains essential files and scripts
- Related scripts grouped logically
- Professional project appearance

### **📚 Better Documentation**
- Each script directory has its own README
- Clear purpose and usage for each script category
- Easier onboarding for new team members

## 🔄 **Migration Plan:**

1. **Create script directories**
2. **Move scripts to appropriate folders**
3. **Create wrapper scripts for backward compatibility**
4. **Update documentation and README**
5. **Test all script functionality**

## 📋 **Backward Compatibility:**

All existing script calls will continue to work:
```bash
./init.sh dev              # Still works
./deploy.sh dev            # Still works  
./validate-backend.sh      # Still works
```

New organized structure also available:
```bash
./scripts/testing/test-health-notification.sh dev
./scripts/utilities/setup-summary.sh
```
