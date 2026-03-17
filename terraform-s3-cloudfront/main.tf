
# provider <service provider name>
provider "aws" {
  region = "ap-south-1"
}

# resource "resource-type" "current-resource-name" { ... }
# provider provides different types of resources
# each resource has its own attributes
# can add multiple resources of same type but different name
# use resource attribute with
# <resource-type>.<resource-name>.<attr-name>



# SETP 1. create s3 bucket

resource "aws_s3_bucket" "bucket_asset_store" {
    bucket = "asset-store-12345"

    tags = {
        Name = "aws-with-terraform"
    }
}

# STEP 2. set lifecycle rule

resource "aws_s3_bucket_lifecycle_configuration" "cleanup_temp_everyday" {
  bucket = aws_s3_bucket.bucket_asset_store.id

  rule {
    id = "delete-temp-files" 
    status = "Enabled"

    filter {
      prefix = "temp/" # object with temp/ prefix will be auto deleted
    }

    expiration {
      days = 1
    }
  }
}

# STEP 3. configure the OAC (id card) 

resource "aws_cloudfront_origin_access_control" "access_origin_asset_store" {
    name = "s3-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}


# STEP 4: create CloudFront distribution

resource "aws_cloudfront_distribution" "asset_store_cdn" {
    enabled = true

    # origin = source of content
    origin {
      # attach the s3 bucket as the source, 
      domain_name = aws_s3_bucket.bucket_asset_store.bucket_regional_domain_name
      origin_id = "s3-origin" # use any string but unique in this cloud front

      origin_access_control_id = aws_cloudfront_origin_access_control.access_origin_asset_store.id
    }

    default_cache_behavior {
    # when cloud front got a request it search the given origin for the content
      target_origin_id = "s3-origin"

      viewer_protocol_policy = "redirect-to-https" # force to https only

      # basic CORS, only read allowed
      allowed_methods = ["GET","HEAD"]
      cached_methods = ["GET","HEAD"]

      forwarded_values {
        query_string = false

        cookies {
          forward = "none"
        }
      }
    }

    # settings for SSL certificate. 
    # if i use custom domain name for cloudfront, then change this
    viewer_certificate {
      cloudfront_default_certificate = true
    }

    restrictions {

      # restrict geo location from accessing this cloud front  
      geo_restriction {
        restriction_type = "none"
      }
    }
}

# STEP 5: add s3 bucket policy

# OAC vs Buckt Policy:
# policy asks the service, who want to access the s3 content, to show the id card
# OAC creates the id card 

resource "aws_s3_bucket_policy" "asset_store_allow_cloudfront" {
    bucket = aws_s3_bucket.bucket_asset_store.id

    # add bucket policy to give minimum permission to colud front to get object
    # without this policy cloud front will always fail to read content from s3
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "cloudfront.amazonaws.com"
                }
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.bucket_asset_store.arn}/*"
                Condition = {
                    StringEquals = {
                        "AwS:SourceArn" = aws_cloudfront_distribution.asset_store_cdn.arn
                    }
                }
            }
        ]
    })
}