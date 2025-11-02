# ecs deployment pipeline with infrastructure as code

## problems encountered

### 1. codedeploy service restriction

**error:**
```
Error: creating CodeDeploy Application (ecs-bg-deploy-app):
SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service
```

aws starter account requires up to 24 hours for codedeploy service activation. codedeploy is free for ecs deployments but has account activation timing restrictions.

**sources:**
- https://aws.amazon.com/codedeploy/pricing/
- https://repost.aws/knowledge-center/create-and-activate-aws-account

### 2. elastic load balancer restriction

**error:**
```
Error: creating ELBv2 application Load Balancer (ecs-bg-deploy-alb):
OperationNotPermitted: This AWS account currently does not support creating load balancers.
For more information, please contact AWS Support.
```

aws starter account has service-level restrictions on creating load balancers requiring aws support intervention.

## alternative approach taken

given the account restrictions and timeline constraints:

1. **replaced codedeploy blue/green** → **ecs rolling updates**
   - still achieves zero-downtime deployments
   - native ecs deployment controller

2. **replaced load balancer** → **ecs tasks with public ips**
   - tasks deployed in public subnets with direct internet access
   - security groups control access

codedeploy configuration preserved in `terraform/codedeploy.tf.disabled` for future use once account restrictions are lifted.
