#!/bin/bash
# This script runs when the EC2 instance starts

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Get region from instance metadata
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${ecr_repository_uri}

# Create deployment script
cat > /home/ec2-user/deploy.sh << 'EOF'
#!/bin/bash
set -e

ECR_URI="${ecr_repository_uri}"
AWS_REGION="${aws_region}"
IMAGE_TAG="$${1:-latest}"

echo "🚀 Starting deployment..."
echo "ECR URI: $ECR_URI"
echo "Image Tag: $IMAGE_TAG"

# Stop existing container
echo "Stopping existing container..."
docker stop devops-app || true
docker rm devops-app || true

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Pull latest image
echo "Pulling latest image..."
docker pull $ECR_URI:$IMAGE_TAG

# Start new container
echo "Starting new container..."
docker run -d \
  --name devops-app \
  -p 3000:3000 \
  --restart unless-stopped \
  -e APP_VERSION=$IMAGE_TAG \
  $ECR_URI:$IMAGE_TAG

echo "✅ Deployment complete!"
docker ps
EOF

# Make script executable
chmod +x /home/ec2-user/deploy.sh
chown ec2-user:ec2-user /home/ec2-user/deploy.sh

# Create log file
echo "✅ EC2 instance setup completed at $(date)" > /home/ec2-user/setup.log
