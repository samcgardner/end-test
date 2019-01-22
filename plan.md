[this is written as a go-live document aimed at developers, explaining a new platform
and how to develop for and deploy on it]
# Go-Live Plan for END. Clothing Web Platform
Hello there! This is a go-live plan for END.'s new microservices-based Web Platform,
which will rely on Kubernetes to orchestrate containers and Terraform to create supporting cloud 
resources such as databases and load balancers.
It's pretty high-level, but it tries to cover a few key points that we'd like all 
services to adhere to from now on so that we can make developing and deploying them as 
easy as possible and let everyone get on with the important stuff. The things we'd like to 
standardise from now on are as follows:
* Repository Layout
* Code Building
* Deployment
* Configuration and Secret Management
* Monitoring

In order to make this as painless as possible, we've provided a service generator
[out-of-character-note: not really, it's a stub] which will generate skeletons of 
new microservices that comply with out new schema, which you can run with 
`./svcgen $SERVICE_NAME`. We've also converted all existing microservices to use the 
new format. For the sake of clarity, we've detailed the new way of doing things in this document.

# Repository Layouts
From now on, we would like services and libraries to live in a mono-repository as 
top-level folders in this repository. Each folder should correspond to one artifact,
which could be a microservice, a library, a cron job, or a cloud-based resource such as a message queue.
Each folder may contain a makefile specifying steps required to build it and Kubernetes or Terraform
files describing cloud resources that should be created or updated. For an example, please see `service-hello-world`.
For an example of a service that does not depend on creating a microservice, have a look at `resource-mysql`.

# Code Building
[out-of-character-note: I've done this with makefiles to avoid being language-specific or ci-system specific.
obviously these aren't appropriate for every situation, I've just gone with them as a lowest common denominator
approach]
How your code builds is up to you! The only requirement is that you expose a `make build`
command that will build it, and that it produce an artifact that is stored in an appropriate
company repository - whether that is a container registry, Artifactory, or somewhere else entirely.
If your code has tests, they should be exposed through the `make test` command. You're encouraged
to use a multi-stage docker build to try and ensure that builds are as quick as possible (and if
you've used `svcgen` that's what you'll be doing) but this isn't strictly enforced. `make test` and 
`make build` will be run in order on every commit.

# Deployment
Two forms of "deployment" will happen - if a docker image has been built, it will be pushed to the container
registry, and if you have Terraform or Kubernetes manifests included, and they've changed, these will be applied.
The default is that deployments need to be manually triggered on a per-environment basis, and are always applied
in the following order:
1. Terraform
2. Kubernetes
3. Container pushed

There is no explicit mechanism for rolling back deployments - this is because some forms of rollback
(e.g. removing a resource like a database that depends on persistent storage) would risk losing data.
If you are deploying a change to a service that you later discover needs to be reverted, you can simply 
create a new commit that reverts your changes. With that said, you are strongly encouraged
to try and avoid this situation - between unit, application, and integration tests, as well as 
liveness and readiness probes on your deployments, it should be very rare that a rollback is needed. 

# Configuration and Secrets
Where possible, you should seek to write 12-Factor Apps (https://12factor.net/config).
This means that configuration should be restricted to things that change on a per-environment basis
(everything else should live inside your repo as code) and be exposed through environment variables.
The pattern assumed by the CI/CD system is that there will be at most two configuration files,
sourced in the following order:
1. `default.env`
2. `$ENVIRONMENT_NAME.env`
Meaning that environment-specific settings will override defaults.

For secret management, you are encouraged to use Kubernetes secrets. These are also exposed
as environment varibles, but are not readable from the monorepo in the way that configuration is.
There are a few limitations to this that you should be aware of:
1. Other developers cannot see which secrets are available unless you document this. Services
that rely on secrets should mention this fact and explain their use in their `Readme.md` file.
2. Kubernetes secrets can only be used within Kubernetes.
3. Kubernetes secrets can be retrieved by any developer, and thus offer strictly limited secrecy.

Due to limitations 2 and 3, anything that needs to be accessed outside of Kubernetes or which needs
to be secure against retrieval by developers (e.g. banking details) should be stored in Vault,
which is documented else [stub].

# Monitoring and Alerting
Note: You are strongly encouraged to read, or at least skim, https://landing.google.com/sre/sre-book/chapters/monitoring-distributed-systems/
and https://landing.google.com/sre/sre-book/chapters/practical-alerting/
Monitoring is done with Prometheus, using Grafana to provide visualisations. 
By default, prometheus will scrape two endpoints, one to get information about CPU usage, free and consumed RAM,
and other broad-brush metrics about the underlying docker container, and one to read specific metrics 
about your application from a `/metrics` endpoint. Monitoring and alerting is a pretty complicated topic,
but broadly speaking there are two kinds of monitoring and several tiers of alerting, and you're going to need to think about all of them.
Let's break things down a little, starting with monitoring. The two kinds are:
1. Black Box Monitoring
2. White Box Monitoring

Black box monitoring describes the kind of things we can measure about every application - is it 
alive and reachable, is the CPU usage in an acceptable range, is memory available, and so forth.
It is important, but you shouldn't rely on it - services can fail without noticeably impacting system resources.
It's vital that you also monitor the internals of your application - things like its request volume,

the percentage of failing requests, or tail user latencies. Having a detailed view of all your
application's internals will let you generate an alert promptly when any of them become concerning.
Most of your monitoring should be white box monitoring. This is, unfortunately, also 
the kind of monitoring that can't be generated for you - you're going to have to think 
about and test your service and write monitoring rules by hand. A good rule of thumb is to
focus on the 'Four Golden Signals'
1. Latency
2. Traffic
3. Errors
4. Saturation (i.e. how utilised your most constrained resource is - bearing in mind that
you may see performance degradation below 100% utilisation)


Once you've decided what to monitor, you need to decide what to do when you see a problem.
Broadly speaking, there are three tiers of response:
1. Page somebody
2. Create an incident report requiring prompt (<4h or <8h) response time
3. Create an incident report requiring non-urgent resolution  

This needs to be guided by common sense and business needs. If what you're alerting on
is really important, such as the website going down, a page is probably appropriate.
If it's a problem but nothing is on fire, it's probably an incident requring prompt response.
Anything else is just an incident. Be careful not to alert too much - it's very easy
to end up creating non-urgent alarms for everything that end up being ignored.

I know that can seem like a bit much, especially if you don't have any previous experience
of this sort of thing, so if you have questions, the DevOps team are here to help. Just
shoot us a message on Slack.
