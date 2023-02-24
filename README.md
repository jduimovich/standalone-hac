# Standalone HAC

This repository installs a Stone Soup backend and a HAC UX frontend on a single cluster.

# Installation Steps

You will need a standalone cluster (clusterbot or a large CRC) with kubeadmin


* Pre-Install infra-deployments https://github.com/redhat-appstudio/infra-deployments and wait til completion
  * `./hack/bootstrap-cluster.sh preview --toolchain --keycloak`
* Verify that the toolchain login is working. You need to login (see infra-deployments for pw). This will ensure the user tenant and workspace is configured for HAC. You can register at his endpoint. 

 `echo "https://"$(kubectl get routes -n toolchain-host-operator registration-service -o jsonpath={.spec.host})`

* Create a fork of this repo and clone it. This is required so that the scripts can customize the installation.
* OPTIONAL - Set the SOUP_HOSTNAME variable for your cluster eg `export SOUP_HOSTNAME=cluster-hostname` This will point the routes for the hac frontends to this hostname.
The code will try to compute and validate the reachability of a generated hostname for Stone Soup. You should not have to set this variable in most situations.
* Secrets and config - You will need to create a directory `hack/nocommit`  (copy `./hack/no-commit-templates`).
You need credentials from your quay.io account in the correct formats and place these in the `nocommit` directory.
* Run `./hack/install.sh` and it will install clowder, the ArgoCD applications for HAC.

Note, the install will always install from a preview- branch.
This is because it will change the gitops repo to reference the branch and repo itself.
Keeping these changes in a separate branch makes it easier to submit pull requests back to upstream as you separate out repo names and branch names from the upstream which references its own repo and the `main` branch.



# Dev Mode

This repo supports dev mode. The deployment is always done in preview mode.

If you want to test a new HAC image you can run `./hack/show-current-images` to see what you have and whether there are new images.
Note -this skips PR images but if you want to use those, fix the image references in the yaml reference below. 
```
OK: quay.io/cloudservices/frontend-operator:a54395e
OK: quay.io/cloudservices/hac-core-frontend:ee51c55
Needs update: quay.io/cloudservices/hac-dev-frontend:d273bef  in file: components/hac-boot/hac-dev.yaml (current is: 016a454)
yq -i .spec.image="quay.io/cloudservices/hac-dev-frontend:d273bef" /home/john/dev/standalone-hac/hack/../components/hac-boot/hac-dev.yaml
OK: quay.io/cloudservices/insights-chrome-frontend:42b63e8
```

You can also run ` ./hack/find-latest-images` and it will update the images to the latest it can find.

```
OK: quay.io/cloudservices/frontend-operator:a54395e
OK: quay.io/cloudservices/hac-core-frontend:ee51c55
OK: quay.io/cloudservices/insights-chrome-frontend:42b63e8
Update: quay.io/cloudservices/hac-dev-frontend:d273bef  in file: components/hac-boot/hac-dev.yaml (current is: 016a454)
```



 