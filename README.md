# 🚀 Twingate Zero Trust Network Access on AWS

Production-grade Terraform infrastructure for deploying Twingate Zero Trust Network Access (ZTNA) solution on AWS, enabling secure remote access to private resources without traditional VPNs.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)
- [Migration Guide](#migration-guide)
- [FAQ](#faq)

## 🎯 Overview

This infrastructure deploys a **Zero Trust Network Access** solution using Twingate, providing secure, identity-based access to private AWS resources without exposing them to the internet or requiring traditional VPN infrastructure.

### What is Twingate?

Twingate is a modern Zero Trust Network Access (ZTNA) platform that replaces legacy VPNs with a more secure, faster, and easier-to-manage solution. Unlike traditional VPNs that provide broad network access, Twingate provides granular, application-level access based on user identity.

### Why Choose This Over Traditional VPN?

| Feature | Traditional VPN | Twingate ZTNA |
|---------|----------------|---------------|
| **Access Model** | Network-level (too broad) | Application-level (granular) |
| **Setup Complexity** | Complex certificates & config | Simple, no client config needed |
| **Performance** | Single gateway bottleneck | Split tunnel, optimized routing |
| **User Experience** | Slow, clunky, "always-on" | Fast, seamless, on-demand |
| **Security** | Castle-and-moat | Zero Trust, least privilege |
| **Management** | Manual user/group management | Integrated with IdP (Okta, Azure AD) |
| **Scalability** | Limited, expensive | Highly scalable |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Twingate Cloud                          │
│                    (Control Plane - SaaS)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Identity   │  │    Policy    │  │  Analytics   │         │
│  │   Provider   │  │    Engine    │  │  Dashboard   │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────┬───────────────────────────────────┘
                              │ Encrypted Control Channel
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│                             │         AWS Cloud                 │
│                             │                                   │
│  ┌──────────────────────────▼────────────────────────────────┐ │
│  │              VPC (10.0.0.0/16)                            │ │
│  │                                                            │ │
│  │  ┌─────────────────────────┐  ┌─────────────────────────┐│ │
│  │  │   Public Subnet (AZ-1)  │  │  Private Subnet (AZ-1) ││ │
│  │  │                         │  │                         ││ │
│  │  │  ┌──────────────────┐   │  │  ┌──────────────────┐  ││ │
│  │  │  │    Twingate      │   │  │  │    Demo VM       │  ││ │
│  │  │  │    Connector     │◄──┼──┼──┤  (Private)       │  ││ │
│  │  │  │   (t3.micro)     │   │  │  │   Ubuntu 22.04   │  ││ │
│  │  │  └────────┬─────────┘   │  │  └──────────────────┘  ││ │
│  │  │           │              │  │                         ││ │
│  │  │      Secure Tunnel       │  │  No Public IP          ││ │
│  │  │           │              │  │  10.0.11.0/24          ││ │
│  │  └───────────┼──────────────┘  └─────────────────────────┘│ │
│  │              │                                             │ │
│  │         Internet Gateway                                   │ │
│  └──────────────┼─────────────────────────────────────────────┘ │
│                 │                                                │
└─────────────────┼────────────────────────────────────────────────┘
                  │
        ┌─────────▼──────────┐
        │   End Users        │
        │ (Twingate Client)  │
        │  Any Location      │
        └────────────────────┘
```

### Data Flow

1. **User Authentication**: User logs in via Twingate client → Twingate Cloud authenticates via IdP
2. **Policy Evaluation**: Twingate Cloud checks access policies for requested resource
3. **Connection Establishment**: If authorized, secure tunnel created: User → Connector → Private Resource
4. **Zero Knowledge**: Twingate Cloud never sees actual data, only facilitates connection

## ✨ Features

### Security
- ✅ **Zero Trust Architecture**: Never trust, always verify
- ✅ **Identity-Based Access**: Tied to user identity, not network location
- ✅ **Least Privilege Access**: Granular resource-level permissions
- ✅ **No Exposed Attack Surface**: Private resources remain completely hidden
- ✅ **Encrypted Connections**: All traffic encrypted end-to-end
- ✅ **No Inbound Firewall Rules**: Connector makes outbound-only connections

### Operations
- ✅ **No Client Configuration**: Users don't need to manage certificates or config files
- ✅ **Split Tunneling by Default**: Only authorized traffic goes through Twingate
- ✅ **Multi-Cloud Support**: Works across AWS, Azure, GCP, on-premises
- ✅ **Easy User Management**: Integrates with existing identity providers
- ✅ **Real-Time Analytics**: Connection logs, user activity, resource access

### Infrastructure
- ✅ **Lightweight Connector**: Single t3.micro instance (upgradeable)
- ✅ **High Availability**: Deploy multiple connectors for redundancy
- ✅ **Auto-Scaling Ready**: Connector supports horizontal scaling
- ✅ **No NAT Gateway Required**: Reduces AWS costs significantly

## 📦 Prerequisites

### Required Accounts
- **AWS Account** with appropriate IAM permissions
- **Twingate Account** (sign up at [twingate.com](https://www.twingate.com))
  - Free tier available for small teams
  - Get your network name (e.g., `mycompany.twingate.com`)

### Required Tools
- **Terraform**: >= 1.0
- **AWS CLI**: >= 2.0 (configured with credentials)
- **Twingate Admin Access**: To create connectors and configure access

### Twingate Setup

1. **Create Twingate Account**:
   ```bash
   # Sign up at https://www.twingate.com/signup
   # Note your network name: <your-network>.twingate.com
   ```

2. **Get Twingate API Key**:
   - Go to Settings → API → Create API Key
   - Save the API key securely

3. **Install Twingate Client** (for end users):
   - Download from: https://www.twingate.com/download
   - Available for Windows, macOS, Linux, iOS, Android

## 🚀 Quick Start

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd twingate-aws-infrastructure
```

### Step 2: Configure Twingate Provider

Create `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"
azs        = ["us-east-1a", "us-east-1b"]

# Network Configuration
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

# Twingate Configuration
tg_network = "mycompany"  # Your Twingate network name
tg_api_token = "your-api-token-here"  # From Twingate Admin Console
```

### Step 3: Configure Provider Authentication

Create `provider.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    twingate = {
      source  = "Twingate/twingate"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "twingate" {
  api_token = var.tg_api_token
  network   = var.tg_network
}
```

### Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy (takes ~5 minutes)
terraform apply

# Note the outputs
terraform output
```

### Step 5: Configure User Access

```bash
# 1. Invite users in Twingate Admin Console
# Settings → Users → Invite User

# 2. Add users to the "aws group"
# Access → Groups → aws group → Add Users

# 3. Users download Twingate client and sign in
# https://www.twingate.com/download
```

### Step 6: Test Access

```bash
# Users can now access the private instance:
# 1. Open Twingate client and sign in
# 2. Connect to resource "aws web server"
# 3. Access private instance via its private IP
ping <private-instance-ip>
ssh ubuntu@<private-instance-ip>
```

## ⚙️ Configuration

### Network Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region | `us-east-1` | No |
| `azs` | Availability zones | `["us-east-1a"]` | Yes |
| `public_subnets` | Public subnet CIDRs | - | Yes |
| `private_subnets` | Private subnet CIDRs | - | Yes |

### Twingate Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `tg_network` | Twingate network name (subdomain) | Yes |
| `tg_api_token` | Twingate API token | Yes |

### Instance Configuration

| Resource | Type | Purpose |
|----------|------|---------|
| `twingate_connector` | t3.micro | Secure access gateway |
| `demo_vm` | t3.micro | Example private resource |

### Scaling Connectors

For production, deploy multiple connectors for high availability:

```hcl
resource "aws_instance" "twingate_connector" {
  count = 3  # Deploy 3 connectors
  # ... rest of configuration
  
  availability_zone = element(var.azs, count.index)
  subnet_id        = element(module.twingate_vpc.public_subnets, count.index)
  
  tags = {
    Name = "Twingate Connector ${count.index + 1}"
  }
}
```

### Advanced Resource Configuration

```hcl
# Multiple resources with different access policies
resource "twingate_resource" "database" {
  name              = "Production Database"
  address           = aws_instance.database.private_ip
  remote_network_id = twingate_remote_network.aws_network.id
  
  protocols {
    allow_icmp = false
    tcp {
      policy = "RESTRICTED"
      ports  = ["5432"]  # PostgreSQL only
    }
    udp {
      policy = "DENY_ALL"
    }
  }
  
  access_group {
    group_id = twingate_group.database_admins.id
    security_policy_id = twingate_security_policy.mfa_required.id
  }
}

# Service account access (for CI/CD, automation)
resource "twingate_service_account" "ci_cd" {
  name = "CI/CD Pipeline"
  resources = [twingate_resource.database.id]
}
```

## 🔒 Security

### Security Architecture

**Defense in Depth**:
1. **Identity Layer**: User authenticated via IdP (Okta, Azure AD, Google)
2. **Policy Layer**: Twingate enforces granular access policies
3. **Network Layer**: Private resources have no public IPs
4. **Application Layer**: Optional MFA per resource

### Connector Security

The Twingate Connector:
- ✅ Makes **outbound-only** connections (no inbound ports)
- ✅ Uses mutual TLS for all connections
- ✅ Doesn't store any credentials on the instance
- ✅ Auto-updates with security patches
- ✅ Runs in user-space (no kernel dependencies)

### Best Practices

#### 1. Secure Token Storage

**DO NOT** commit tokens to version control:

```hcl
# Use environment variables
export TF_VAR_tg_api_token="your-token"

# Or use AWS Secrets Manager
data "aws_secretsmanager_secret_version" "twingate" {
  secret_id = "twingate/api-token"
}

provider "twingate" {
  api_token = data.aws_secretsmanager_secret_version.twingate.secret_string
  network   = var.tg_network
}
```

#### 2. Implement MFA

```hcl
resource "twingate_security_policy" "require_mfa" {
  name = "Require MFA"
  mfa_required = true
}

resource "twingate_resource" "sensitive_app" {
  # ... other config
  access_group {
    group_id = twingate_group.admins.id
    security_policy_id = twingate_security_policy.require_mfa.id
  }
}
```

#### 3. Restrict Security Groups

The connector security group is overly permissive. **For production**:

```hcl
resource "aws_security_group" "twingate_security_group" {
  name   = "twingate-sg"
  vpc_id = module.twingate_vpc.vpc_id

  # Remove this - too permissive
  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # Only allow outbound connections
  egress {
    description = "Twingate control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Access to private resources"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR only
  }
}
```

#### 4. Enable Logging

```hcl
# CloudWatch logging for connector
resource "aws_cloudwatch_log_group" "twingate_connector" {
  name              = "/aws/ec2/twingate-connector"
  retention_in_days = 30
}

# Send connector logs to CloudWatch
user_data = <<-EOT
  #!/bin/bash
  # ... existing config
  
  # Configure CloudWatch agent
  yum install -y amazon-cloudwatch-agent
  cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
  {
    "logs": {
      "logs_collected": {
        "files": {
          "collect_list": [{
            "file_path": "/var/log/twingate/*.log",
            "log_group_name": "/aws/ec2/twingate-connector",
            "log_stream_name": "{instance_id}"
          }]
        }
      }
    }
  }
  EOF
  systemctl enable amazon-cloudwatch-agent
  systemctl start amazon-cloudwatch-agent
EOT
```

#### 5. Network Segmentation

```hcl
# Separate private resources by sensitivity
private_subnets_db   = ["10.0.21.0/24", "10.0.22.0/24"]
private_subnets_app  = ["10.0.31.0/24", "10.0.32.0/24"]

# Deploy dedicated connectors per segment
resource "twingate_connector" "db_connector" {
  remote_network_id = twingate_remote_network.database_network.id
}

resource "twingate_connector" "app_connector" {
  remote_network_id = twingate_remote_network.app_network.id
}
```

### Compliance

Twingate helps meet compliance requirements:
- **SOC 2 Type II**: Twingate is SOC 2 certified
- **HIPAA**: Supports HIPAA compliance requirements
- **PCI DSS**: Helps meet network segmentation requirements
- **Zero Trust**: Aligns with NIST 800-207 Zero Trust guidelines

## 📊 Monitoring

### Twingate Analytics Dashboard

Access built-in analytics:
```
https://<your-network>.twingate.com/analytics
```

**Key Metrics**:
- Active users and connections
- Resource access patterns
- Failed authentication attempts
- Connector health and status
- Bandwidth usage per resource

### CloudWatch Monitoring

```bash
# Monitor connector instance
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<connector-instance-id> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average

# Check connector network throughput
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name NetworkOut \
  --dimensions Name=InstanceId,Value=<connector-instance-id> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Recommended Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "connector_cpu" {
  alarm_name          = "twingate-connector-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Connector CPU usage is high"
  
  dimensions = {
    InstanceId = aws_instance.twingate_connector.id
  }
}

resource "aws_cloudwatch_metric_alarm" "connector_status" {
  alarm_name          = "twingate-connector-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Connector instance status check failed"
  
  dimensions = {
    InstanceId = aws_instance.twingate_connector.id
  }
}
```

### Audit Logging

Twingate automatically logs:
- All connection attempts (successful and failed)
- User authentication events
- Policy changes
- Resource access
- Connector status changes

Export logs via:
- Twingate Admin Console
- Twingate API
- SIEM integrations (Splunk, DataDog, etc.)

## 🔧 Troubleshooting

### Connection Issues

#### Problem: User can't connect to resources

**Diagnosis**:
```bash
# Check if user is in the correct group
# Go to Twingate Admin Console → Access → Groups

# Verify resource configuration
terraform state show twingate_resource.aws_resource

# Check connector status in Twingate Console
# Admin → Connectors → Status should be "Online"
```

**Solutions**:
1. Verify user is added to the access group
2. Ensure connector is running: `systemctl status twingate-connector`
3. Check connector security group allows outbound HTTPS (443)
4. Verify user has latest Twingate client installed

#### Problem: Connector shows "Offline"

**Diagnosis**:
```bash
# SSH to connector instance
ssh -i your-key.pem ubuntu@<connector-public-ip>

# Check connector service
sudo systemctl status twingate-connector
sudo journalctl -u twingate-connector -n 50

# Check connector configuration
sudo cat /etc/twingate/connector.conf

# Test connectivity to Twingate cloud
curl -v https://<your-network>.twingate.com
```

**Solutions**:
1. Restart connector: `sudo systemctl restart twingate-connector`
2. Verify tokens are valid (not expired)
3. Check security group allows outbound HTTPS
4. Verify internet gateway is attached to VPC

#### Problem: Can reach connector but not private resources

**Diagnosis**:
```bash
# From connector instance, test private resource
ping <private-instance-ip>
telnet <private-instance-ip> 80

# Check routing
ip route show
```

**Solutions**:
1. Verify private instance security group allows traffic from connector
2. Check route tables - connector subnet should route to private subnet
3. Ensure private instance is in the same VPC

### Performance Issues

#### Problem: Slow connection speeds

**Possible Causes**:
- Connector instance undersized (t3.micro may be insufficient for many users)
- Single connector creating bottleneck
- Network latency between connector and resources

**Solutions**:
```hcl
# Upgrade connector instance type
resource "aws_instance" "twingate_connector" {
  instance_type = "t3.small"  # or t3.medium for heavy usage
  # ... rest of config
}

# Deploy multiple connectors
resource "aws_instance" "twingate_connector" {
  count = 3  # High availability
  # ... rest of config
}
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `INVALID_CREDENTIALS` | Expired or invalid API token | Regenerate token in Twingate Console |
| `CONNECTOR_OFFLINE` | Connector can't reach Twingate Cloud | Check security groups, internet connectivity |
| `RESOURCE_NOT_FOUND` | Resource address incorrect | Verify private IP hasn't changed |
| `UNAUTHORIZED` | User not in access group | Add user to appropriate group |
| `MFA_REQUIRED` | MFA policy enforced but user hasn't set up | User must configure MFA in Twingate app |

## 💰 Cost Estimation

### Monthly Cost Breakdown (us-east-1)

| Service | Usage | Cost |
|---------|-------|------|
| Twingate Service | 5 users | $0 (Free tier) or $10/user* |
| EC2 Connector (t3.micro) | 1 × 730 hours | ~$7.59 |
| EC2 Demo VM (t3.micro) | 1 × 730 hours | ~$7.59 |
| EBS Volumes (gp3) | 2 × 8 GB | ~$1.60 |
| Data Transfer OUT | 10 GB | ~$0.90 |
| **No NAT Gateway** | Saved! | **-$32.85** |
| **No VPN Endpoint** | Saved! | **-$72.00** |

**Total AWS Cost**: ~$17.68/month
**Twingate Cost**: Free (up to 5 users) or ~$50/month (5 users × $10)

**Savings vs Traditional VPN**: ~$87/month (53% cost reduction)

*Pricing varies by plan. Check [twingate.com/pricing](https://www.twingate.com/pricing)

### Cost Optimization

1. **Right-size connectors based on usage**:
   - t3.nano: 1-10 concurrent users
   - t3.micro: 10-25 concurrent users
   - t3.small: 25-50 concurrent users
   - t3.medium: 50-100 concurrent users

2. **Use Spot Instances for dev/test connectors**:
```hcl
resource "aws_spot_instance_request" "twingate_connector" {
  ami           = data.aws_ami.twingate.id
  instance_type = "t3.micro"
  spot_price    = "0.005"  # ~50% savings
  # ... rest of config
}
```

3. **Terminate demo resources when not needed**

4. **Use Twingate free tier** for small teams (up to 5 users)

## 🔄 Migration Guide

### Migrating from Traditional VPN

**Step 1: Parallel Deployment**
- Deploy Twingate alongside existing VPN
- Don't remove VPN immediately

**Step 2: Identify Resources**
```bash
# List all resources currently accessed via VPN
# Create corresponding Twingate resources
terraform plan -target=twingate_resource.resource_name
```

**Step 3: Pilot Group**
- Select 5-10 users for pilot
- Add them to Twingate group
- Provide Twingate client installation instructions
- Collect feedback

**Step 4: Gradual Rollout**
- Migrate users in batches of 20-30%
- Monitor Twingate analytics for issues
- Keep VPN running until all users migrated

**Step 5: Decommission VPN**
```bash
# After 30 days of successful Twingate usage
terraform destroy -target=aws_vpn_endpoint.vpn
```

### Migrating from Bastion Hosts

**Benefits**:
- No more SSH key management
- No need to maintain bastion instances
- Audit trail of all access
- No public IPs on bastion hosts

**Migration**:
```hcl
# Replace this:
resource "aws_instance" "bastion" {
  # Bastion host config
}

# With this:
resource "twingate_resource" "private_servers" {
  name    = "SSH Access to Private Servers"
  address = "10.0.11.0/24"  # Entire subnet
  
  protocols {
    tcp {
      policy = "RESTRICTED"
      ports  = ["22"]  # SSH only
    }
  }
  
  access_group {
    group_id = twingate_group.devops.id
  }
}
```

Users can now SSH directly:
```bash
# No bastion jump required!
ssh ubuntu@10.0.11.5
```

## 📖 Advanced Configurations

### Multi-Region Deployment

```hcl
# Deploy connectors in multiple regions
module "twingate_us_east" {
  source     = "./modules/twingate-region"
  region     = "us-east-1"
  tg_network = var.tg_network
}

module "twingate_eu_west" {
  source     = "./modules/twingate-region"
  region     = "eu-west-1"
  tg_network = var.tg_network
}

# Users automatically routed to nearest connector
```

### Service Account Access (CI/CD)

```hcl
# For automated systems that need access
resource "twingate_service_account" "github_actions" {
  name = "GitHub Actions"
  
  resources = [
    twingate_resource.database.id,
    twingate_resource.api.id
  ]
}

resource "twingate_service_account_key" "github_key" {
  service_account_id = twingate_service_account.github_actions.id
  name              = "Production Key"
}

# Use in GitHub Actions
# Set TWINGATE_SERVICE_KEY as secret
```

### Integration with AWS SSO

```hcl
# Twingate supports SAML/OIDC with AWS SSO
# Configure in Twingate Admin Console:
# Settings → Authentication → Add Identity Provider → AWS SSO

# Users authenticate with AWS SSO credentials
# Groups and permissions sync automatically
```

## ❓ FAQ

### General Questions

**Q: How is this different from AWS VPN?**
- Twingate is application-level, AWS VPN is network-level
- Twingate has better user experience (no manual config)
- Twingate includes identity-based access and analytics
- Twingate is often cheaper (no VPN endpoint charges)

**Q: Do I need a VPN license?**
- No, Twingate is a SaaS service with per-user pricing
- Free tier available for up to 5 users

**Q: Can I use this with on-premises resources?**
- Yes! Deploy connectors on-premises or in any cloud
- Same configuration, different network location

**Q: What happens if connector goes down?**
- Deploy multiple connectors for high availability
- Twingate automatically routes to healthy connectors
- Users experience transparent failover

### Technical Questions

**Q: How do I rotate connector tokens?**
```bash
# Generate new tokens in Twingate Console
# Update user_data with new tokens
terraform apply -replace=aws_instance.twingate_connector
```

**Q: Can I use this with containers/Kubernetes?**
- Yes, Twingate provides Helm charts
- Deploy connectors as Kubernetes deployments
- See: https://docs.twingate.com/docs/connector-kubernetes

**Q: Does this work with IPv6?**
- Yes, Twingate supports dual-stack IPv4/IPv6

**Q: How do I backup configuration?**
```bash
# Terraform state contains all configuration
terraform state pull > backup.tfstate

# Twingate configuration via API
curl -H "Authorization: Bearer $TG_API_TOKEN" \
  https://api.twingate.com/v1/networks/<network>/resources
```

## 📚 Additional Resources

- **Official Documentation**: https://docs.twingate.com
- **Terraform Provider**: https://registry.terraform.io/providers/Twingate/twingate
- **Community Forum**: https://community.twingate.com
- **Support**: support@twingate.com
- **Security Whitepaper**: https://www.twingate.com/security

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -m 'Add improvement'`)
4. Push to branch (`git push origin feature/improvement`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- Twingate team for the excellent ZTNA platform
- AWS for cloud infrastructure
- Terraform community

## ⚠️ Important Notes

1. **Security**: The example security group is overly permissive. Restrict it in production (see Security section)
2. **Tokens**: Never commit API tokens to version control. Use environment variables or secrets management
3. **High Availability**: Deploy multiple connectors across AZs for production workloads
4. **Monitoring**: Set up CloudWatch alarms and review Twingate analytics regularly
5. **Cost**: Remember to destroy demo resources when not needed: `terraform destroy`

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/your-org/repo/issues)
- **Twingate Support**: support@twingate.com
- **Documentation**: https://docs.twingate.com
- **Community**: https://community.twingate.com

---

**Built with ❤️ for Zero Trust Security**

*Last Updated: December 24, 2024*
