# ecs deployment pipeline with infrastructure as code

## problems encountered

### 1. codedeploy service restriction

**error:**
```
Error: creating CodeDeploy Application (ecs-bg-deploy-app):
SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service
```

aws starter account requires up to 24 hours for codedeploy service activation. while codedeploy is free for ecs deployments, new accounts face activation timing restrictions that prevented immediate implementation.

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

given the account restrictions and timeline constraints, two key architectural changes were made to maintain the core requirement of zero-downtime deployments.

instead of codedeploy blue/green deployments, the implementation uses ecs native rolling updates. this approach still achieves zero-downtime by gradually replacing old tasks with new ones while maintaining minimum healthy task counts. the native ecs deployment controller handles the orchestration without requiring additional services.

the load balancer was replaced with ecs tasks deployed in public subnets with directly assigned public ips. security groups control inbound access to the tasks, maintaining security while simplifying the architecture. this works well for the demonstration purpose though a production system would typically use a load balancer for traffic distribution and health checking.

the original codedeploy configuration has been preserved in `terraform/codedeploy.tf.disabled` for future use once account restrictions are lifted.

## observing deployments

### original requirement vs implementation

the original assignment required blue/green deployments using aws codedeploy. however, due to the codedeploy service restriction on the aws starter account, this couldn't be implemented. instead, ecs rolling updates were used as an alternative that still achieves zero-downtime deployments.

the key difference is that blue/green deployments maintain two complete environments and switch traffic instantly between them, while rolling updates gradually replace old tasks with new ones while maintaining minimum healthy count. both approaches achieve zero downtime, but the transition mechanism differs.

### how to observe rolling deployment behavior

to see the deployment process in action, start by making a visible change to the application code. for example, update the version from "1.0.0" to "1.0.1" in `app/index.js` or modify the response message. once you commit and push these changes to the master branch, the github actions workflow automatically handles the rest.

the workflow builds the docker image with the correct platform architecture (linux/amd64 for ecs fargate), pushes it to ecr, and triggers an ecs service update. during the deployment transition, you can query the running tasks and observe both old and new versions responding simultaneously. as ecs gradually drains the old tasks and brings up new ones, the traffic shifts smoothly without any downtime.

the entire pipeline is automated through the `.github/workflows/deploy.yml` workflow, which triggers automatically on changes to the `app/**` directory.

## infrastructure changes

infrastructure updates use a safer two-step workflow to prevent accidental destructive changes and state locking conflicts.

### automatic plan on push

when you push terraform changes to the `terraform/**` directory, github actions automatically runs `tofu plan` to validate and show what changes will be made. importantly, it does not automatically apply these changes. this gives you a chance to review the planned modifications before they affect your live infrastructure.

### manual apply via workflow dispatch

to actually apply infrastructure changes, navigate to github actions and find the infrastructure updates workflow. click "run workflow" and select the "apply" action from the dropdown. this manual step ensures you've reviewed the plan output and are ready to proceed with the changes.

this two-step approach prevents accidental infrastructure destruction, avoids state locking conflicts between local and ci/cd runs, and ensures all changes go through a review step before being applied.

**note:** if you need to run terraform locally, ensure no github actions workflows are running to avoid state lock conflicts. if you encounter lock errors, check the dynamodb table `ecs-bg-deploy-tfstate-lock` and remove stale locks if necessary.
