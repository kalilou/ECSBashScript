#!/usr/bin/env bash

# Bash script for export the docker environment variables
export AWSRegion=YourRegion
export AWSAccountID=YourAWSAccountID
export applicationName=YourapplicationName
export clusterName=YourCluster
export ecsServiceName=YourService
export taskDefinitionName=YourTaskDefinitioFamily


repo=`aws ecr describe-repositories --region $AWSRegion --repository-names $applicationName`

if [[ -z $repo ]]
    then aws ecr create-repository --region $AWSRegion --repository-name $applicationName
else 
    echo "Repo $applicationName already exists"
fi 

docker build -t $applicationName . 

eval $(aws ecr get-login --region $AWSRegion)

docker tag $applicationName:latest $AWSAccountID.dkr.ecr.$AWSRegion.amazonaws.com/$applicationName:latest

docker push $AWSAccountID.dkr.ecr.$AWSRegion.amazonaws.com/$applicationName:latest


taskRevision=`aws ecs register-task-definition --region $AWSRegion --cli-input-json file://./nginx_task.json | jq .taskDefinition.revision`

echo $taskRevision

ecsName=`aws ecs list-services --region $AWSRegion --cluster $clusterName --output text | grep $ecsServiceName | sed 's:^.*/::g'`

if [[  -z $ecsName ]]
    then aws ecs create-service --region $AWSRegion --cluster $clusterName --service-name $ecsServiceName --task-definition $taskDefinitionName:$taskRevision --desired-count 0
else 
    aws ecs update-service --region $AWSRegion --cluster $clusterName --service $ecsServiceName --task-definition $taskDefinitionName:$taskRevision --desired-count 0
fi 

ecsServiceName=`aws ecs list-services --region $AWSRegion --cluster $clusterName --output text | grep $ecsServiceName | sed 's:^.*/::g'`

echo $ecsServiceName


