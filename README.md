# Contents 
1. [AWS account initialisation](#aws-account-initialisation)
2. [Setup AWS access](#setup-aws-access)
3. [Terraform Setup](#terraform-setup)

# AWS account initialisation

These steps need to be executed once. Just after creating separate AWS account. In the perfect world it should
be kept as separate terraform configuration responsible for account management.

For now execute once or ensure that everything is in place.

## Set up a new role `AdminRole`

Grant this role to all infrastructure administrator users

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::127121982953:user/zbik",
          "arn:aws:iam::127121982953:user/zbikapi"
        ]
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
```
Attach AWS managed policy `AdministratorAccess` - `(arn:aws:iam::aws:policy/AdministratorAccess)`.

## Create AWS credentials for CLI tools

Setup AWS cli credentials (IAM/Users/<user>/Security credentials/Access key)

## Switch AWS console role to AdminRole

https://signin.aws.amazon.com/switchrole?roleName=AdminRole&account=565393064003

# Setup AWS access

The shared AWS config and credentials files contain a set of profiles. A profile is a set of configuration values
that can be referenced from the SDK/tool using its profile name. Configuration values are attached to a profile in
order to configure some aspect of the SDK/tool when that profile is used.

In IAM setup CLI access key. Setup AWS credentials.
Add following entry to `~/.aws/config`

## Configuration types

**admin** for administrator to maintain the infrastructure part and setup account resources.
It is a single configuration for all non-production environments. It consists of the following AWS profiles:
 * `sandbox-login` base profile, declares AWS credentials to use
 * `sandbox-admin` to be used for Terraform operations, use `sadnbox-login` and then switch IAM role 
 * `sandbox-state` declares AWS credentials to use for Terraform to store state (backend)

In order to activate profile for command line usage select profile by setting up AWS environment variable, e.g.

`export AWS_PROFILE=sandbox-admin`

## Configuration examples

Profiles in `~/.aws/config`
```
[profile sandbox-login]
region = eu-west-1

[profile sandbox-state]
region = eu-west-1

[profile sandbox-admin]
region = eu-west-1
role_arn = arn:aws:iam::565393064003:role/AdminRole
source_profile = sandbox-login

```
Add credentials to `~/.aws/credentials`
```
[sandbox-login]
aws_access_key_id = A...........B
aws_secret_access_key = a..........................y

[sandbox-state]
aws_access_key_id = A...........B
aws_secret_access_key = a..........................y
```

# Terraform Setup

## Initial setup

Terraform stores infrastructure state information in the [state file](https://developer.hashicorp.com/terraform/language/state).
For more than one developer/devops such state file need to be shared. It is also required to keep it secure (encrypt)
as it contains all soft of sensitive information.

[S3 state backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) is fulfilling these
requirements. As its name suggest it is using aws S3 bucket for storing state file. Additionally, it can use
AWS dynamoDB for locking. Locking is optional and not required yet (simply try to clash with other developers).

### S3 bucket

Single S3 bucket can hold multiple state files (for different projects), however we decided to create separate bucket
for each project. Still it will be possible to store more than one terraform state file if there is separate
terraform for main (core) infrastructure and separate used by software developers.

AWS account used for storing state file can be different than AWS account for a target infrastructure. It is intended
configuration solving the chicken and egg problem.

It is good idea to enable bucket versioning.

#### Bucket permissions

Terraform need base S3 operations Get/Put/List/Delete operations. It is possible to separate devops(admins) and developers
if you assume that state are stored with different key prefix (directory). Bellow there is a sample configuration.

```json
{
  "Version": "2012-10-17",
  "Id": "state",
  "Statement": [
    {
      "Sid": "software",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::127121982953:user/zbikapi",
          "arn:aws:iam::127121982953:user/zbik"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::zbik-state-sandbox/infrastructure/*",
        "arn:aws:s3:::zbik-state-sandbox"
      ]
    }
  ]
}
```

## Encryption keys

S3 support client side data encryption. In such situation encryption takes place before data is send to AWS, local
tools (clients) need to know encryption key. Terraform assume that key will be passed as base64 encoded and key length
need to be 256 bits (32 bytes). Such key can be generated by `openssl rand 32 -base64`.

Secure storing of such key is another matter. It can be stored in the file which exists on 'secure' disk (for example
protected by password).

This key is created once, by one person, at the first state initialisation
and is then used in any need of access to the state, by each user.

```shell
openssl rand 32 -base64 > ~/.secure/zbik-sandbox/admin.key
```

Terraform S3 backend is smart enough to get encryption key from env variable `AWS_SSE_CUSTOMER_KEY`, so that it will
be not visible in  command line by other users. Of course setting up such env variable have to be performed in a way
which guarantee that copy of credentials is not stored in shell history file. For example:

```shell
export AWS_SSE_CUSTOMER_KEY=$(cat ~/.secure/zbik-sandbox/admin.key)
```

#### Conventions

By convention the keys should be stored by each user under `~/.secure/` directory followed by path
specific to environment and purpose, e.g.
* `~/.secure/zbik-sandbox/admin.key`

Since a particular key is always used in combination with a particular AWS profile
it appears useful to set both, key and profile, environment variables together, e.g. in an 
`env.sh` file defined per each environment, like below:

```shell
export AWS_PROFILE=sandobx-zbik-admin
export AWS_SSE_CUSTOMER_KEY=$(cat ~/.secure/zbik-sandobx/admin.key)
```

Then such `env.sh` file can be sourced in order to "switch" to a particular environment:

```shell
source env.sh
```

#### Initialise terraform

```shell
terraform init
```

> WARNING: Please note that `AWS_SSE_CUSTOMER_KEY` have to be properly set. It is good idea to double check
> if created state file is encrypted. It should fail complaining to missing encryption key when you try to
> to get it by `aws s3 cp` or from AWS web console.

# Adding a new devops and/or developer

There are two steps required
1. add a new user to bucket permissions
2. share bucket encryption key (after long explanation/indoctrination how important it is to store it secure)
