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

## observing deployments

### original requirement vs implementation

the original assignment required blue/green deployments using aws codedeploy. however, due to the codedeploy service restriction on the aws starter account, this couldn't be implemented. instead, ecs rolling updates were used as an alternative that still achieves zero-downtime deployments.

**key differences:**
- **blue/green**: maintains two complete environments, switches traffic instantly between them
- **rolling updates**: gradually replaces old tasks with new ones while maintaining minimum healthy count

### how to observe rolling deployment behavior

to see the deployment process in action:

1. make a visible change to the application (e.g., update version from "1.0.0" to "1.0.1")
2. rebuild docker image with `--platform linux/amd64` and push to ecr
3. trigger deployment: `aws ecs update-service --cluster ecs-bg-deploy-cluster --service ecs-bg-deploy-service --force-new-deployment --region us-west-2`
4. monitor progress and get task ips to test endpoints
5. during the transition, both old and new versions respond simultaneously as ecs gradually drains old tasks and brings up new ones
