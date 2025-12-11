# create_v1_secrets.ps1
# SAFE version for GitHub – contains ONLY placeholder values.

$Region = "eu-west-2"

Write-Host "Creating V1 Secrets in AWS Secrets Manager..." -ForegroundColor Cyan

##############################################
# 1) DB PASSWORD SECRET
##############################################
aws secretsmanager create-secret `
  --name "/custom-snipeit-v1/db_password" `
  --description "Snipe-IT V1 MySQL password" `
  --secret-string '{"value":"CHANGE_ME"}' `
  --region $Region

##############################################
# 2) APP_KEY SECRET
##############################################
aws secretsmanager create-secret `
  --name "/custom-snipeit-v1/app_key" `
  --description "APP_KEY for Snipe-IT V1" `
  --secret-string '{"value":"base64:CHANGE_ME"}' `
  --region $Region

##############################################
# 3) API TOKEN SECRET (JWT placeholder)
##############################################
aws secretsmanager create-secret `
  --name "/custom-snipeit-v1/snipeit_api_token" `
  --description "JWT API token for Snipe-IT V1" `
  --secret-string '{"value":"PLACEHOLDER"}' `
  --region $Region

##############################################
# 4) FLASK SECRET KEY
##############################################
aws secretsmanager create-secret `
  --name "/custom-snipeit-v1/flask_secret_key" `
  --description "Flask SECRET_KEY for V1" `
  --secret-string '{"value":"CHANGE_ME"}' `
  --region $Region

Write-Host "Secrets created successfully! (Now replace placeholders in AWS Console)" -ForegroundColor Green
