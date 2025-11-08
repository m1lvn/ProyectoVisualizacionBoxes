# PowerShell helper to import existing resources into Terraform state
# Review and uncomment the imports you want to run.

# Import EC2 instance
# terraform import aws_instance.django_server i-010bfa0287dcf8911

# Import security group
# terraform import aws_security_group.ec2_sg sg-056763fe7a2a028c8

# Import S3 bucket
# terraform import aws_s3_bucket.lambda_bucket proyecto-hospital-lambda-code-y8fkerqb

# Import S3 object (lambda.zip)
# terraform import aws_s3_object.lambda_code "proyecto-hospital-lambda-code-y8fkerqb/lambda.zip"

# Import Lambda function
# terraform import aws_lambda_function.api proyecto-hospital-api

# Import Key Pair
# terraform import aws_key_pair.deployer my-ec2-key

# Import Instance Profile
# terraform import aws_iam_instance_profile.lab_instance_profile proyecto-hospital-lab-instance-profile

Write-Host "Review and uncomment the lines above to import resources into state."