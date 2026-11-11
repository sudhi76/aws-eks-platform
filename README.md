# aws-eks-platform

Terraform for a production-style Amazon EKS platform: a three-AZ VPC, an EKS cluster with Graviton spot nodes, ECR, encrypted remote state, and keyless GitHub Actions access through OIDC.

It is written as small modules of my own rather than wrapping the community modules, so every resource and setting is visible and explained.

> **Status:** code complete and checked in CI (fmt, validate, test, tflint, Trivy). Not yet applied to a live account; see [Roadmap](#roadmap).

## Architecture

```
                         ┌──────────────── VPC 10.0.0.0/16 (ap-south-1) ────────────────┐
                         │                                                               │
  internet ── IGW ──────►│  public /24 ×3     load balancers, NAT gateway                │
                         │        │                                                      │
                         │        ▼ (egress only)                                        │
                         │  private /19 ×3    EKS managed nodes (arm64, spot)            │
                         │                    pods get VPC IPs from the VPC CNI          │
                         └───────────────────────────────────────────────────────────────┘
                                  │
          EKS control plane ◄─────┘  API: private endpoint + public endpoint limited to your IP
          Secrets encrypted with a customer KMS key; api/audit/authenticator logs in CloudWatch

  S3 state bucket (versioned, KMS, TLS-only, native lockfile)     ECR (immutable tags, scan on push)
  GitHub OIDC provider ──► github-terraform-plan role (read-only, pull requests of this repo only)
```

## Layout

```
bootstrap/         one-time stack: state bucket, KMS key, GitHub OIDC provider and plan role
modules/
  network/         VPC, public/private subnets per AZ, NAT, routes, flow logs, locked-down default SG
    tests/         offline tests: subnet CIDRs, NAT gateway modes, input validation
  eks/             cluster, access entries, KMS, control plane logs, add-ons, managed node group
  ecr/             repositories with lifecycle policies
envs/
  dev/             composes the modules; add envs/prod/ the same way
.github/workflows/ fmt, validate, test, tflint and Trivy on every pull request
```

## Design decisions

| Decision | Why |
|---|---|
| Graviton (`t4g`/`m7g`) spot nodes | Spot is usually 60–70% below on-demand, and Graviton about 20% cheaper than comparable x86. The images this cluster runs are built for `arm64` and `amd64`. Two instance types give spot more capacity pools to draw from. |
| One NAT gateway in dev | Saves about $65 a month. Egress fails if that AZ goes down, which is fine for dev. `single_nat_gateway = false` gives one per AZ. |
| Private /19 subnets | The VPC CNI gives every pod a VPC IP, so node subnets need room for pods, not just nodes. |
| Access entries, `authentication_mode = "API"` | No `aws-auth` ConfigMap to break, and cluster access is visible in Terraform. The creator of the cluster gets no hidden admin rights. |
| IMDSv2 with hop limit 1 | Pods cannot read the node role's credentials. Workloads get AWS access through EKS Pod Identity (the agent add-on is installed). |
| `upgrade_policy = STANDARD` | When a Kubernetes version leaves standard support, EKS upgrades it instead of silently billing extended support at six times the price. |
| CoreDNS created after the node group | The other add-ons must exist before nodes can become Ready; CoreDNS needs nodes to schedule onto. |
| S3 native locking (`use_lockfile`) | Terraform 1.10+ locks state in S3 itself, so no DynamoDB table is needed. |
| OIDC instead of access keys | GitHub Actions gets short-lived credentials; the role trusts only pull requests of this repository. |

Trivy reports no HIGH or CRITICAL findings. The remaining LOW/MEDIUM ones are deliberate for a dev environment: no customer KMS key for CloudWatch logs and ECR, no access logging on the state bucket, and no scheduler/controller-manager logs (each adds cost and is rarely read).

## Usage

Requirements: Terraform 1.10 or later, the AWS CLI logged in with an admin role (IAM Identity Center recommended, not the root user).

**1. Bootstrap (once per account)**

```sh
cd bootstrap
terraform init
terraform apply
```

This keeps its own state locally. To move it into the bucket it just created, add a `backend "s3"` block and run `terraform init -migrate-state`.

**2. Create the dev environment**

```sh
cd envs/dev
cp backend.hcl.example backend.hcl            # set the bucket from the bootstrap output
cp terraform.tfvars.example terraform.tfvars  # your IP and your admin role ARN
terraform init -backend-config=backend.hcl
terraform plan -out=dev.tfplan
terraform apply dev.tfplan                    # about 15 minutes
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

**3. Tear it down when you are done**

```sh
terraform destroy
```

## Cost

Approximate on-demand prices in `ap-south-1` while the dev environment is running:

| Item | Per hour |
|---|---|
| EKS control plane | $0.10 |
| NAT gateway (plus data processed) | $0.056 |
| 2 × `t4g.medium` spot | about $0.03 |
| Public IPv4, EBS, KMS, CloudWatch | about $0.01 |
| **Total** | **about $0.20 (about $5 a day)** |

Destroy after each session; nothing in `envs/dev` is meant to run permanently. Set an AWS Budgets alert before the first apply.

## Roadmap

- [x] Network, EKS and ECR modules; dev environment
- [x] Encrypted, versioned remote state with native locking
- [x] CI: fmt, validate, `terraform test` with a mocked provider, tflint (AWS ruleset), Trivy misconfiguration scan
- [ ] First apply in a real account; screenshots of the running cluster
- [ ] `terraform plan` posted on pull requests through the OIDC role
- [ ] AWS Load Balancer Controller and Karpenter, with Pod Identity roles
- [ ] Argo CD bootstrapped onto the cluster to deploy [LinkPulse](https://github.com/sudhi76/linkpulse)
- [ ] `prod` environment: NAT gateway per AZ, on-demand baseline nodes

## License

[MIT](LICENSE)
