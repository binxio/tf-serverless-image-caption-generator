# Serverless generation of captions for images on GCP using VertexAI
This Terraform module sets up the necessary resources in Google Cloud for a simple application that stores captions for images in Firestore.
The application will store images in a Cloud Storage bucket, and once an image is stored, a Python Cloud Function is triggered to process the image.
Subsequently the VertexAI caption that is generated is stored in Firestore.

## Resources Created:
- Firestore Database: For data storage.
- Cloud Storage Bucket: To store the uploaded images and the Cloud Function's source code.
- Pub/Sub Topic: For bucket notifications when a new image is added.
- Cloud Function: Python-based Cloud Function that is triggered when a new image is added to the bucket.
- IAM roles and permissions: The necessary roles and permissions for the Cloud Function to access Firestore and other required services.

## Prerequisites:
- Terraform installed.
- Google Cloud SDK (gcloud) installed and initialized.
- Appropriate permissions on Google Cloud to create resources.

## How to Deploy:
Clone the Repository:

```bash
git clone git@github.com:binxio/tf-serverless-image-caption-generator.git
cd tf-serverless-image-caption-generator
```

Initialise Terraform:
```bash
terraform init
```

Update Variables:
You may want to adjust default values for the project_id, region, and location in the Terraform files or override them using -var option with terraform apply.

Review and Apply Changes:

```bash
terraform plan
terraform apply
```

Review the resources that will be created/modified and type yes when prompted.

Once deployed, navigate to the Google Cloud Console to ensure that the resources have been created.
If you wish to remove all resources created by Terraform:

```bash
terraform destroy
```

## Notes
The Cloud Function's source code should be placed in the function directory. The current setup considers main.py as the main entry point and requirements.txt for any dependencies.
The Cloud Function is packaged into a ZIP archive whenever there's a change in either main.py or requirements.txt. This ensures that the function is redeployed only when its source changes.
Ensure you have the necessary IAM permissions to create and manage these resources on Google Cloud.
