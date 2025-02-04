# Develop

## Installing OpenShift (CodeReady Containers)

If you already have a working OpenShift environment to deploy to, this step
is not necessary. If however you are interested in creating a local
development environment to develop and test for, read along.

[CodeReady Containers](https://code-ready.github.io/crc/) is a tool to create
a local installation of OpenShift 4.x. It supports Windows, Linux, and Mac but
for the purposes of this we're only focusing on the latter two.

Unfortunately, it needs to be [registered with Red Hat](https://cloud.redhat.com/openshift/create/local)
to receive a secret necessary for installation.

Place the secret in `tools/crc/pullstring.json` and run:

```bash
./tools/crc/setup_crc.sh tools/crc/pullstring.json
```

## Running the code locally

### Install dependencies

You'll need to make sure you have an environment with the necessary
dependencies installed. One solution is create a Python virtual
environment in the source directory. To create a new virtual
environment and activate it:

```sh
$ python -m venv .venv
$ . .venv/bin/activate
```

Now we can go ahead and install the dependencies:

```sh
$ pip install -r requirements.txt -r test-requirements.txt
```

In the future, you can activate the virtual environment by simply
re-sourcing the `activate` script:

```sh
$ . .venv/bin/activate
```

### Configure the environment

Create a file named `.env` with the following content:

```sh
FLASK_ENV=development
OPENSHIFT_URL=https://api.crc.testing:6443
ACCT_MGT_ADMIN_PASSWORD=pass
ACCT_MGT_IDENTITY_PROVIDER=developer
```

(You can modify `OPENSHIFT_URL` as necessary if you are not using a
local CRC deployment as your OpenShift environment.)

### Start the service

Start the service like this:

```
ACCT_MGT_AUTH_TOKEN=$(oc whoami -t) flask run -p 8080
```

The service is now available at <http://localhost:8080>.  Using curl,
you would access it like this:

```
$ curl -u admin:pass http://localhost:8080/projects/test-project
{"msg": "project does not exist (test-projectx)"}
```

## Running the code in CodeReady Containers

### Deploying to CRC

First, start building the docker image and pushing it to the [internal
CodeReady Containers registry](
https://code-ready.github.io/crc/#accessing-the-internal-openshift-registry_gsg).

For that, we first need to log in to the registry. If you're using RHEL/CentOS,
substitute `docker` for `podman` in the command below.

```bash
docker login -u kubeadmin -p $(oc whoami -t) default-route-openshift-image-registry.apps-crc.testing
docker build . -t default-route-openshift-image-registry.apps-crc.testing/onboarding/openshift-acct-mgt:latest
docker push default-route-openshift-image-registry.apps-crc.testing/onboarding/openshift-acct-mgt:latest
```

After the image has been build and pushed, we can apply the kustomization specs.
This will install all the necessities for deploying and running the service,
including a service account and cluster role binding.

```bash
oc apply -k k8s/overlays/crc
```

Of particular note is the ImageStream to point to a local image via the
`lookupPolicy` `local` attribute.

```yaml
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: openshift-acct-mgt
spec:
  lookupPolicy:
    local: true
```

The above commands are part of the script located in `tools/crc/deploy.sh`.

## Testing

Running the tests requires passing `--amurl` as an argument with the URL endpoint
for the OpenShift API. For CodeReady containers, that is
<https://onboarding-onboarding.apps-crc.testing>.

Addtionally You can either use the command line --basic <user>:<pass>
or to set environment variables ACCT_MGT_USERNAME and
ACCT_MGT_PASSWORD to your configured username and password
respectively.  The command line credentials overide the credentials in
the environment variables

```bash
cd tests
pip install -r test-requirements
python3 -m pytest --amurl https://openshift-onboarding.apps-crc.testing --basic user:pass
```

or 

```bash
cd tests
pip install -r test-requirements
export ACCT_MGT_USERNAME=admin
export ACCT_MGT_PASSWORD=pass
python3 -m pytest --amurl https://openshift-onboarding.apps-crc.testing
```
