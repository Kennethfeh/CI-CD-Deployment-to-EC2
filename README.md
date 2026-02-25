# CI/CD Deployment to AWS EC2

End-to-end example of shipping a containerised Node.js application to a hardened EC2 instance. GitHub Actions builds the Docker image, ships it to Amazon ECR, Terraform provisions the infrastructure, and cloud-init boots the instance with the latest image.

## Flow overview

```
Developer push → GitHub Actions → Build & test → Push image to ECR → Terraform provisions VPC + EC2 → User data pulls the new image → App served via ALB/EC2
```

## Repository structure

| Path | Description |
| --- | --- |
| `app/` | Express application exposing `/` and `/health`. Includes a Dockerfile and npm scripts. |
| `project-2-containers/` | Legacy container project kept for reference (shared scripts + Docker assets). |
| `terraform/` | Infrastructure-as-code for the VPC, public subnet, security groups, EC2 instance profile, Amazon ECR repository, and user-data bootstrap. |
| `.github/workflows/deploy.yml` | GitHub Actions pipeline that runs tests, builds/pushes the Docker image, and (optionally) triggers Terraform from a runner. |
| `trust-policy.json` | OIDC trust relationship for GitHub Actions → AWS role assumptions. |

## Prerequisites

- AWS account with permissions to create VPC, EC2, IAM, and ECR resources.
- Terraform ≥ 1.0, AWS CLI v2, Docker, and Node.js 18 installed locally.
- SSH key pair for EC2 logins (public key referenced in `terraform/terraform.tfvars`).
- GitHub repository secrets:
  - `AWS_ROLE_ARN` – IAM role GitHub Actions assumes.
  - `AWS_REGION` – Region to deploy into.

## Local application workflow

```bash
cd app
npm install
npm start # http://localhost:3000
curl http://localhost:3000/health
```

Build the container image locally:

```bash
docker build -t devops-demo-app:local app/
```

## Terraform deployment

```bash
cd terraform
terraform init
terraform apply \
  -var="project_name=devops-ec2" \
  -var="aws_region=us-east-1" \
  -var="public_key=$(cat ~/.ssh/id_rsa.pub)"
```

Terraform output includes the EC2 public IP, security group ID, and ECR repository URI. Destroy resources when finished to avoid costs:

```bash
terraform destroy
```

## GitHub Actions pipeline

1. **Checkout & setup Node.js** – Installs dependencies for the `app/` folder.
2. **Tests** – Runs `npm test` (placeholder today) and linting hooks if added later.
3. **Container build** – Logs into ECR using OIDC + temporary credentials, builds the Node.js image, and pushes tags `latest` + commit SHA.
4. **(Optional) Deployment** – Terraform apply/destroy can run via workflow dispatch or manual approval if wired in.

Update `.github/workflows/deploy.yml` with environment-specific steps (e.g., SSM Parameter Store updates) as you productionise the pipeline.

## EC2 bootstrap

`terraform/user-data.sh` executes on first boot:

- Installs Docker + dependencies.
- Logs into ECR.
- Pulls the freshly built image.
- Runs the container on port 3000 under `systemd` supervision.

SSH into the instance using the key pair and tail `/var/log/user-data.log` if provisioning ever fails.

## Security and operations

- Security group exposes only ports 22 (SSH) and 3000 (app). Adjust as needed (e.g., front with ALB + TLS).
- IAM role attached to the EC2 instance includes least-privilege ECR read permissions.
- Enable CloudWatch Logs/metrics or install a Datadog/Prometheus agent if you need deeper telemetry.

## Next steps

- Swap the sample Express app with your service while keeping the CI/Terraform scaffolding.
- Add automated `terraform plan`/`apply` stages triggered after successful image builds.
- Layer on vulnerability scanning (Trivy, Grype) before pushing images, and run synthetic probes against `http://<EC2-IP>:3000/health` post-deploy.

This repo gives you a legible blueprint for promoting container images straight onto EC2 when Kubernetes is overkill or not yet available.
