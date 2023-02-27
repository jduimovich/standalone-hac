# Standalone HAC

This repository installs a Stone Soup backend and a HAC UX frontend on a single cluster.

# Installation Steps

You will need a standalone cluster (clusterbot or a large CRC) with kubeadmin


* Pre-Install infra-deployments https://github.com/redhat-appstudio/infra-deployments and wait til completion
  * `./hack/bootstrap-cluster.sh preview --toolchain --keycloak`

If this is your first time installing infra-deployments, please read the installation notes, specifically setting up the preview.env file which will contain all your specific creds, repo and org configs for your personal version of stone soup. This is needed to ensure your images go to quay.io in an org you have access to, as well as your github org for the gitops repos generated by stone soup. 

* Verify that the toolchain login is working. You need to login (see infra-deployments for pw). This will ensure the user tenant and workspace is configured for HAC. You can register at his endpoint. 

    `echo "https://"$(kubectl get routes -n toolchain-host-operator registration-service -o jsonpath={.spec.host})`

  Tip: If you see errors on this page, you may be having CERT/TLS errors from untrusted servers.
  Run the following and click on the URL(s), and approve the access to the site. This may happen even if you've logged in before so check the links below if having registration issues. 
  
  `echo  https://"$(kubectl get routes -n toolchain-host-operator registration-service -o jsonpath={.spec.host})"/landingpage.js"`
  
  `echo  https://"$(kubectl get routes -n dev-sso keycloak -o jsonpath={.spec.host})"/auth/js/keycloak.js`
  

* Create a fork of this repo and clone it. This is required so that the scripts can customize the installation.
* OPTIONAL - Set the SOUP_HOSTNAME variable for your cluster

   `export SOUP_HOSTNAME=cluster-hostname` 

This will point the routes for the hac frontends to this hostname.
The code will try to compute and validate the reachability of a generated hostname for Stone Soup. You should not have to set this variable in most situations.

* Secrets and config - You will need to create a directory `hack/nocommit`  (copy `./hack/no-commit-templates`).
You need credentials from your quay.io account in the correct formats and place these in the `nocommit` directory.
* Run `./hack/install.sh` and it will install clowder, the ArgoCD applications for HAC.

Note, the install will always install from a preview- branch.
This is because it will change the gitops repo to reference the branch and repo itself.
Keeping these changes in a separate branch makes it easier to submit pull requests back to upstream as you separate out repo names and branch names from the upstream which references its own repo and the `main` branch.



# Dev Mode

This repo work supports development as all deployments are always done in preview mode.
Preview mode works the same as in the infra-deployments repository. When you make changes to your branch and commit them locally (no need to push), you then run `./hack/preview.sh` which will take your branch and create a `preview-` variation. 

This variation will:
 1. update the repository references to your fork repository name. This is to have the gitops service serve the resources from your fork. The names are updated in the temporary `preview-` branch to make submitting changes to upstream easier.
 2. create a `preview-<branchname>` with the repo and revision references update to the `preview-<branchname>` that has been pushed to github.  

For example, to test new HAC images you can run `./hack/show-current-images` to see what you have and whether there are new images. This is a non-destructive operation and only shows the images.  To actually update the image references in the repo use ` ./hack/find-latest-images` which will find and update the images.

Note -Finding the latest images skips pull-request images but if you want to use those, you can change the image references in the yaml reference below to whatever images you like. For HAC developers, this can be personal builds as part of your developer flow. 

The output will look like this. You can click on any link to see how old your images are . 
```
OK: quay.io/cloudservices/frontend-operator:a54395e
OK: quay.io/cloudservices/hac-core-frontend:ee51c55
Needs update: quay.io/cloudservices/hac-dev-frontend:d273bef  in file: components/hac-boot/hac-dev.yaml (current is: 016a454)
yq -i .spec.image="quay.io/cloudservices/hac-dev-frontend:d273bef" /home/john/dev/standalone-hac/hack/../components/hac-boot/hac-dev.yaml
OK: quay.io/cloudservices/insights-chrome-frontend:42b63e8
```

If you ran   ` ./hack/find-latest-images` you will see updates, run `git status` to see what has changed, or `git diff`. You should see image tags updated to be the latest. 

```
OK: quay.io/cloudservices/frontend-operator:a54395e
OK: quay.io/cloudservices/hac-core-frontend:ee51c55
OK: quay.io/cloudservices/insights-chrome-frontend:42b63e8
Update: quay.io/cloudservices/hac-dev-frontend:d273bef  in file: components/hac-boot/hac-dev.yaml (current is: 016a454)
```

Commit these changes and re-run `./hack/preview.sh`

This same workflow can be used to test any changes in the configuration prior to sending a pull request from the branch your working on. 



 
