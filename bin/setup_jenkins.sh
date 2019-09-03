#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/redhat-gpte-devopsautomation/advdev_homework_template.git na311.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"
echo -e "___________________________________________________________________________________________________________________\n"
# Set up Jenkins with sufficient resources
# TBD

# Set up Jenkins
echo -e "************************ Creation and Configuration of Jenkins Project ************************\n"
echo "oc new-project ${GUID}-jenkins --display-name "${GUID} Shared Jenkins""
oc new-project ${GUID}-jenkins --display-name "${GUID} Shared Jenkins"
echo -e "___________________________________________________________________________________________________________________\n"
echo "new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true"
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true
echo -e "___________________________________________________________________________________________________________________\n"
echo "set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m"
oc set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m
echo -e "___________________________________________________________________________________________________________________\n"

# Set up Dev Project
echo -e "*********************** Setup Dev Project ***********************\n"
echo 
echo -e "___________________________________________________________________________________________________________________\n"
oc new-project ${GUID}-tasks-dev --display-name "${GUID} Tasks Development"
echo 
echo -e "___________________________________________________________________________________________________________________\n"
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"

# Set up Dev Application
echo -e "*********************** Setup Dev Application ***********************\n"
echo "oc new-build --binary=true --name="tasks" jboss-eap71-openshift:1.3 -n ${GUID}-tasks-dev"
oc new-build --binary=true --name="tasks" jboss-eap71-openshift:1.3 -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc new-app ${GUID}-tasks-dev/tasks:0.0-0 --name=tasks --allow-missing-imagestream-tags=true -n ${GUID}-tasks-dev"
oc new-app ${GUID}-tasks-dev/tasks:0.0-0 --name=tasks --allow-missing-imagestream-tags=true -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set triggers dc/tasks --remove-all -n ${GUID}-tasks-dev"
oc set triggers dc/tasks --remove-all -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc expose dc tasks --port 8080 -n ${GUID}-tasks-dev"
oc expose dc tasks --port 8080 -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc expose svc tasks -n ${GUID}-tasks-dev"
oc expose svc tasks -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set probe dc/tasks -n ${GUID}-tasks-dev --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/"
oc set probe dc/tasks -n ${GUID}-tasks-dev --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc create configmap tasks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-tasks-dev"
oc create configmap tasks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set volume dc/tasks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n ${GUID}-tasks-dev"
oc set volume dc/tasks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set volume dc/tasks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-config -n ${GUID}-tasks-dev"
oc set volume dc/tasks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-config -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"

# Set up Production Project
echo -e "*********************** Setup Prod Project ***********************\n"
echo "oc new-project ${GUID}-tasks-prod --display-name "${GUID} Tasks Production""
oc new-project ${GUID}-tasks-prod --display-name "${GUID} Tasks Production"
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-tasks-prod -n ${GUID}-tasks-dev"
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-tasks-prod -n ${GUID}-tasks-dev
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-tasks-prod"
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"

# Create Blue Application
echo -e "*********************** Create and Configure Blue Application ***********************\n"
echo "oc new-app ${GUID}-tasks-dev/tasks:0.0 --name=tasks-blue --allow-missing-imagestream-tags=true -n ${GUID}-tasks-prod"
oc new-app ${GUID}-tasks-dev/tasks:0.0 --name=tasks-blue --allow-missing-imagestream-tags=true -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set triggers dc/tasks-blue --remove-all -n ${GUID}-tasks-prod"
oc set triggers dc/tasks-blue --remove-all -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc expose dc tasks-blue --port 8080 -n ${GUID}-tasks-prod"
oc expose dc tasks-blue --port 8080 -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set probe dc tasks-blue -n ${GUID}-tasks-prod --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/"
oc set probe dc tasks-blue -n ${GUID}-tasks-prod --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc create configmap tasks-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-tasks-prod"
oc create configmap tasks-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set volume dc/tasks-blue --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-blue-config -n ${GUID}-tasks-prod"
oc set volume dc/tasks-blue --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-blue-config -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set volume dc/tasks-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-blue-config -n ${GUID}-tasks-prod"
oc set volume dc/tasks-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-blue-config -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"

# Create Green Application
echo -e "*********************** Create and Configure Green Application ***********************\n"
echo "oc new-app ${GUID}-tasks-dev/tasks:0.0 --name=tasks-green --allow-missing-imagestream-tags=true -n ${GUID}-tasks-prod"
oc new-app ${GUID}-tasks-dev/tasks:0.0 --name=tasks-green --allow-missing-imagestream-tags=true -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set triggers dc/tasks-green --remove-all -n ${GUID}-tasks-prod"
oc set triggers dc/tasks-green --remove-all -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc expose dc tasks-green --port 8080 -n ${GUID}-tasks-prod"
oc expose dc tasks-green --port 8080 -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set probe dc tasks-green -n ${GUID}-tasks-prod --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/"
oc set probe dc tasks-green -n ${GUID}-tasks-prod --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc create configmap tasks-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-tasks-prod"
oc create configmap tasks-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set volume dc/tasks-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-green-config -n ${GUID}-tasks-prod"
oc set volume dc/tasks-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-green-config -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set volume dc/tasks-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-green-config -n ${GUID}-tasks-prod"
oc set volume dc/tasks-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-green-config -n ${GUID}-tasks-prod
# Expose Blue service as route to make blue application active
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc expose svc/tasks-blue --name tasks -n ${GUID}-tasks-prod"
oc expose svc/tasks-blue --name tasks -n ${GUID}-tasks-prod
echo -e "___________________________________________________________________________________________________________________\n"

# Create custom agent container image with skopeo
# TBD
echo -e "************************ Creation of Custom Jenkins Agent Pod ************************\n"
echo "oc new-build -D $'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\n
      USER root\nRUN yum -y install skopeo && yum clean all\n
      USER 1001' --name=jenkins-agent-appdev -n ${GUID}-jenkins"
oc new-build -D $'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\n
      USER root\nRUN yum -y install skopeo && yum clean all\n
      USER 1001' --name=jenkins-agent-appdev -n ${GUID}-jenkins
echo -e "___________________________________________________________________________________________________________________\n"

# Create pipeline build config pointing to the ${REPO} with contextDir `openshift-tasks`
# TBD
echo -e "************************ Pipeline Build Configuration ************************\n"

echo "apiVersion: v1
items:
- kind: "BuildConfig"
  apiVersion: "v1"
  metadata:
    name: "tasks-pipeline"
  spec:
    source:
      type: "Git"
      git:
        uri: "https://github.com/manaspatnaik/advdev_homework_template.git"
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        jenkinsfilePath: openshift-tasks/Jenkinsfile
kind: List
metadata: []" | oc create -f - -n ${GUID}-jenkins
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc secrets new-basicauth git-secret --username=<user_name> --password=<password> -n ${GUID}-jenkins"
oc secrets new-basicauth git-secret --password=e86a6e54dc60c2ce7684cc41a7e64f5cd977da3c -n ${GUID}-jenkins
echo -e "___________________________________________________________________________________________________________________\n"
echo "oc set build-secret --source bc/tasks-pipeline git-secret -n ${GUID}-jenkins"
oc set build-secret --source bc/tasks-pipeline git-secret -n ${GUID}-jenkins

# Make sure that Jenkins is fully up and running before proceeding!
while : ; do
  echo "Checking if Jenkins is Ready..."
  AVAILABLE_REPLICAS=$(oc get dc jenkins -n ${GUID}-jenkins -o=jsonpath='{.status.availableReplicas}')
  if [[ "$AVAILABLE_REPLICAS" == "1" ]]; then
    echo "...Yes. Jenkins is ready."
    break
  fi
  echo "...no. Sleeping 10 seconds."
  sleep 10
done




