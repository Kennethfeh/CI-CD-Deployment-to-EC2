**Flow Description:**
1. Code is pushed to the main branch on GitHub.  
2. GitHub Actions automatically builds the Docker image.  
3. The image is pushed to AWS Elastic Container Registry (ECR).  
4. Terraform provisions EC2 infrastructure.  
5. The containerized app is deployed to the EC2 instance.

---

## 🌐 Application Endpoints

| Endpoint | Description |
|-----------|--------------|
| `http://<YOUR-EC2-IP>:3000` | Main application |
| `http://<YOUR-EC2-IP>:3000/health` | Health check endpoint |

---

## 💻 Local Development

To run the app locally:

```bash
cd app
npm install
npm start


GitHub → GitHub Actions → ECR → EC2
