# ecs deployment pipeline with infrastructure as code

## problems i ran into

### 1. codedeploy service restriction

so the first major blocker i hit was with codedeploy. i got this error when trying to set up the blue/green deployment:

```
Error: creating CodeDeploy Application (ecs-bg-deploy-app):
SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service
```

turns out my aws starter account needed up to 24 hours for codedeploy service activation. codedeploy is actually free for ecs deployments, but there's this account activation timing thing that blocked me from using it immediately.

did some research on this:
- https://aws.amazon.com/codedeploy/pricing/
- https://repost.aws/knowledge-center/create-and-activate-aws-account

### 2. load balancer restriction

then i ran into another wall trying to create the application load balancer:

```
Error: creating ELBv2 application Load Balancer (ecs-bg-deploy-alb):
OperationNotPermitted: This AWS account currently does not support creating load balancers.
For more information, please contact AWS Support.
```

my aws starter account has restrictions on creating load balancers that require aws support to lift. given the timeline, i couldn't wait for that.

## what i did instead

with both codedeploy and the load balancer blocked, i had to pivot while still meeting the core requirement of zero-downtime deployments.

**for deployments:** instead of codedeploy blue/green, i went with ecs native rolling updates. it still gives me zero-downtime by gradually replacing old tasks with new ones while keeping the minimum healthy task count. the native ecs deployment controller handles everything without needing codedeploy.

**for networking:** i replaced the load balancer with ecs tasks in public subnets that get public ips assigned directly. security groups control who can access them. this works fine for a demo, though i'd definitely use a proper load balancer in production for traffic distribution and health checking.

i kept the original codedeploy configuration in `terraform/codedeploy.tf.disabled` so i can enable it once the account restrictions are lifted.

## how deployments work

### what the assignment wanted vs what i built

the assignment asked for blue/green deployments with codedeploy. because of the account restriction i mentioned above, i couldn't do that. so i used ecs rolling updates instead, which still achieves zero-downtime.

the main difference: blue/green maintains two complete environments and switches traffic instantly, while rolling updates gradually replace old tasks with new ones. both avoid downtime, just different mechanisms.

### seeing it in action

if you want to see the deployment process, just make a visible change to the app. like change the version from "1.0.0" to "1.0.1" in `app/index.js` or tweak the response message. commit and push to master, and github actions takes over from there.

the workflow builds the docker image (with the right platform - linux/amd64 for ecs fargate), pushes it to ecr, and updates the ecs service. during the transition, you can hit the running tasks and see both old and new versions responding at the same time. ecs gradually drains the old tasks as the new ones come up.

the whole thing runs through `.github/workflows/deploy.yml` which triggers on changes to the `app/**` directory. once deployment finishes, the workflow grabs and displays the public ips of all running tasks so you can test them right away without having to query aws manually.

## zero-downtime infrastructure upgrades

i also needed to support zero-downtime upgrades when changing infrastructure stuff like cpu, memory, environment variables, etc. when i update terraform variables (like bumping `fargate_cpu` from "256" to "512"), the infrastructure workflow applies it via github actions. terraform creates a new task definition revision, then ecs does its rolling update thing: spins up new tasks with the updated config, waits for health checks, then drains the old ones while keeping at least one task running throughout.

**what i changed in the code:** i removed the `lifecycle { ignore_changes = [task_definition] }` block from `terraform/ecs.tf`. that block was preventing terraform from updating the service when infrastructure parameters changed. without it, terraform can now create new task definition revisions and trigger ecs rolling deployments whenever i change infrastructure settings.

## how i handle infrastructure changes

i set up a two-step workflow for infrastructure updates to avoid accidentally destroying things or running into state lock issues.

**automatic plan:** when i push terraform changes to the `terraform/**` directory, github actions automatically runs `tofu plan` to show me what would change. crucially, it doesn't auto-apply anything. this gives me a chance to review before it touches the live infrastructure.

**manual apply:** to actually apply changes, i go to github actions, find the infrastructure updates workflow, hit "run workflow", and select the "apply" action. this manual gate ensures i've looked at the plan and i'm ready to proceed.

this approach prevents me from accidentally nuking infrastructure, avoids state locking conflicts between local runs and ci/cd, and makes sure everything goes through a review step.

**heads up:** if i need to run terraform locally, i make sure no github actions workflows are running to avoid state lock conflicts. if i hit a lock error, i check the dynamodb table `ecs-bg-deploy-tfstate-lock` and clean up stale locks.

## what i'd do differently in production

because of the aws starter account restrictions, i had to skip several things that would be mandatory in production:

**load balancer:** right now i'm exposing ecs tasks directly with public ips. in production, i'd absolutely use an application load balancer for proper traffic distribution, health checking, ssl/tls termination, and a stable endpoint as tasks get replaced. i'd also add service discovery through aws cloud map or route53 for service-to-service communication.

**network architecture:** because i couldn't create the load balancer, i had to put tasks in public subnets with public ips. i would never do this in production. tasks should be in private subnets with traffic routed through a load balancer in public subnets. this reduces the attack surface significantly. nat gateways would handle any outbound internet access needed.

**security groups:** again, because of no load balancer, my security groups currently allow traffic from 0.0.0.0/0 directly to the container port. in production, only the load balancer security group should accept internet traffic, and task security groups should only allow traffic from the load balancer, not the entire internet.

**deployment strategy:** while ecs rolling updates work for zero-downtime, production systems really benefit from true blue/green with codedeploy. you get instant rollback, traffic shifting controls, and canary deployments. especially important for critical apps where you need gradual rollouts and quick rollbacks.

**monitoring:** production would have comprehensive cloudwatch alarms for task health, cpu/memory usage, deployment failures, and app-specific metrics. i'd add aws x-ray for distributed tracing, enhanced container insights, and integration with centralized logging.

i only took these shortcuts because of account restrictions and the timeline. **in production with a proper aws account, i wouldn't accept any of these compromises.**
