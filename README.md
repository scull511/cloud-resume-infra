# cloud-resume-infra

Terraform for the AWS infrastructure behind my online CV at
[cv.simoncull.co.uk](https://cv.simoncull.co.uk). The site itself (an Astro project) lives in
**[cloud-resume](https://github.com/scull511/cloud-resume)**.

This is my take on the [Cloud Resume Challenge](https://cloudresumechallenge.dev): a static site with a serverless visitor counter, all defined as code.

## Architecture

**Static site**

- **S3**: a private bucket holding the built site
- **CloudFront**: serves the site over HTTPS, using Origin Access Control so the bucket can only be
  read through CloudFront
- **CloudFront Function**: rewrites folder-style URLs (`/projects/`) to the `index.html` inside
  them, which a plain S3 origin doesn't do
- **ACM**: TLS certificate (a wildcard cert, created in `us-east-1` as CloudFront requires)
- **Route 53**: DNS for the domain

**Visitor counter**

- **API Gateway** (HTTP API): `GET /views?page=<name>`
- **Lambda** (Python): validates the page name, then increments a per-page counter and a site-wide
  total
- **DynamoDB**: one table, one item per page plus a `total` item
- **IAM**: an execution role limited to `UpdateItem` on that one table, plus CloudWatch logging

The Lambda uses an atomic `ADD` update, so concurrent visits can't overwrite each other, and it
rejects any page name that isn't on an allowlist (or a valid project ID), so arbitrary requests
can't create rows in the table.

## Repo layout

```
*.tf              Terraform, split by service (s3, cloudfront, route53, acm, lambda, ...)
functions/        CloudFront Function source
lambda/           Lambda source code and its tests
```

## State

State is stored remotely in S3 with native state locking (`use_lockfile`). The state bucket was
created by hand with the AWS CLI, as the one bootstrap step. Everything else is managed by
Terraform. State files and `*.tfvars` are not committed.

## How this was built

I built the original stack by hand in the AWS console, then brought it under Terraform with
`terraform import`, one resource at a time, running `terraform plan` after each import until it
showed no changes. Later changes made through Terraform include moving the S3 bucket from public
access to a private bucket with Origin Access Control.

## Running it

Requires Terraform and AWS credentials with access to the account and the state bucket.

```bash
terraform init
terraform plan
terraform apply
```

## Lambda tests

The Lambda's tests use [pytest](https://pytest.org) and [moto](https://github.com/getmoto/moto),
which fakes DynamoDB in memory, so they run with no AWS account.

```bash
cd lambda
python3 -m venv venv
source venv/bin/activate
pip install pytest moto boto3
pytest
```

They cover page validation, project ID matching, and that the per-page and total counters
increment independently.

## Status

GitHub Actions pipelines (build and deploy the site, `terraform plan` on pull requests) are the
next step.
