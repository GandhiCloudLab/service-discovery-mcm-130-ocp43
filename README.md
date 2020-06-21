# MCM Service Discovery in OCP 4.3 Clusters

IBM Multicloud Manager provides service discovery feature among connected managed clusters. 

In this documentation we will see the following
- Configuring DNS in Managed Cluster for Service Discovery
- Installing a sample application 
- Required Kubernetes objects changes for Service Discovery

Versions used : 

IBM Multicloud Manager 1.3.0

Redhat Openshift Container Plantform 4.3

--------------

## 1. Cluster and App Details

The MCM Hub cluster is connected with 2 managed clusters `d` and `e`. Both the managed clusters are installed with Redhat Openshift Container Plantform 4.3.

<img src="images/01-clusters.png" >

The contains 2 services called `frontend` and `catalog`. The `frontend` service deployed in Cluster `d` and it is going to call `catalog` service in that is deployed in Cluster `e`.

<img src="images/02-cluster-app.png" >

--------------

## 2. Configure DNS in Managed Cluster

Need to configure DNS in the Managed Cluster. 

The Knowledge Center page has the detailed explanation about how to do it. https://www.ibm.com/support/knowledgecenter/SSFC4F_1.3.0/mcm/services/mcm_serv_prep.html. But for OCP it is little different and it is explained here.


Do the followings steps in each of your managed cluster.

### 1. Get Service Registry IP Address of the managed cluster

Run the below command. 

```
kubectl get -n multicluster-endpoint service mcm-svc-registry-dns -o jsonpath='{.spec.clusterIP}'
```

You will get the service registry IP printed. The output could be like `111.222.333.444`.


### 2. Update dns.operator/default

#### 1. Run the below command to edit the `dns.operator`

```
oc edit dns.operator/default
```

#### 2. Add the below information under the spec and save.  

```
  servers:
  - forwardPlugin:
      upstreams:
      - << service registry IP>>
    name: mcm-server
    zones:
    - mcm.svc
```

The result would be like this.

<img src="images/11-operator-dns.png" >

#### 3. Viewing Configmap dns-default

The `dns-default` configmap would have been created automatically. Run the below command to see the config map.

```
kubectl get -n openshift-dns configmap dns-default -o yaml
```

The output could be like this.

<img src="images/12-dns-configmap.png" >


#### 4. Viewing Configmap endpoint-svcreg-coredns

The `endpoint-svcreg-coredns` configmap also would have been created automatically. Run the below command to see the config map.

```
kubectl get -n multicluster-endpoint configmap endpoint-svcreg-coredns -o yaml
```

The output could be like this.

<img src="images/13-configmap-endpoint-svcreg-coredns.png" >


#### 5. Viewing Service mcm-svc-registry-dns

Run the below command to see service. 

```
oc describe svc mcm-svc-registry-dns -n multicluster-endpoint 
```

The output could be like this. Here the **endpoints for the mentiond service would be empty**.  This is a probelm in OCP 4.3 version of MCM. This should be solved and next step does that.

<img src="images/14-dns-without-endpoints.png" >


#### 6. Create workaround service

1. Run the below command to create a workaround service that will get created with appropriate endpoints.

```
oc apply -f /files/svc.yaml
```

The svc.yaml file looks like this.

<img src="images/15-workaround-service.png" >


2. Run the below command to see the above created workaround service with appropriate endpoints.

```
oc describe -n multicluster-endpoint service mcm-svc-registry-test
```
The output could be like this. 

<img src="images/16-dns-with-endpoints.png" >


Now this managed cluster is ready for the service discovery. 

You can repeat the same to other managed clusters if any.

--------------

## 3. Installing Sample App

As we have already mentioned, app contains 2 services called `frontend` and `catalog`. The `frontend` service deployed in Cluster `d` and it is going to call `catalog` service in that is deployed in Cluster `e`.

<img src="images/02-cluster-app.png" >

### Installing the App in Hub

#### 1. Login into MCM hub

Login to mcm hub in the command line window using the command like this.

```
oc login ................
```

#### 2. Goto the install folder

Goto the `/deployment/install/` folder

#### 3. Install namespace

Run the below command.

```
sh 01-install-namespace.sh
```

#### 4. Install app

Run the below command.

```
sh 02-install-app.sh
```

### Viewing the installed app

#### 1. Application topology view at MCM Hub

It contains the cluster `d` and `e`.  As planned cluster `d` contains `frontweb` service and cluster `e` contains `catalog` service.

<img src="images/61-App-Topology.png" >

#### 2. Frontweb pod in cluster d

<img src="images/62-ClusterD-pod.png" >

#### 3. Frontweb service in cluster d

<img src="images/63-ClusterD-services.png" >
<img src="images/64-ClusterD-services2.png" >

#### 4. Frontweb routes in cluster d

<img src="images/65-ClusterD-routes.png" >

#### 5. ConfigMap endpoint-svcreg-coredns in cluster d

The DNS we confitured in the previous steps.

<img src="images/66-coredns1.png" >
<img src="images/67-coredns2.png" >

The same entry would exists in cluster `e` as well.

#### 6. Catalog pod in cluster e

<img src="images/68-ClusterE-pod.png" >

#### 7. Catalog service in cluster e

<img src="images/69-ClusterE-services.png" >

#### 5. ConfigMap endpoint-svcreg-coredns in cluster d

It is same in all the cluters.

<img src="images/70-clusterE-coredns1.png" >
<img src="images/71-clusterE-coredns2.png" >


### Run the installed app

1. Goto the Routes Page in cluster `d`. 

<img src="images/65-ClusterD-routes.png" >

2. Click on the route. It should open a application home page.

<img src="images/75-app-home.png" >

3. Click on the catalog link, it will show the output.

<img src="images/76-app-result.png" >

------

## 4. Detailed view of Kubernetes Resources

#### 1. Catalog Deployment

This is a typical `Deployable` MCM resource for `Catalog` service. It contains `Deployment` Kubernetes resource inside.

Line No. 35: Container image

<img src="images/80-catalog-deployment.png" >

#### 2. Catalog Service

This is a typical `Deployable` MCM resource for `Catalog` service. It contains `Service` Kubernetes resource inside.

Line No. 56: The annodation `mcm.ibm.com/service-discovery: "{}"` to be added

Line No. 61: The Type should be `LoadBalancer`

<img src="images/81-catalog-service.png" >

#### 3. Frontweb Deployment

This is a typical `Deployable` MCM resource for `FrontWeb` service. It contains `Deployment` Kubernetes resource inside. 

Line No. 35: Container image

Line No. 38, 41: Service Discovery url to call `Catalog` service is passed from configmap.

Line No. 43: `Dependencies` is declared here. Here `FrontWeb` is depend on `Catalog` service.

Line No. 47: `Placement` is declared here. It means that the `FrontWeb` to be deployed in cluster `d` 

<img src="images/82-frontweb-deployment.png" >

#### 4. Configmap

This configmap is deployed in clusters `d`.  The properties form this configmap is used in `FrontWeb` service.

Line No. 23: URL mentioned here is the URL to discover the `Catalog` service from the FrontWeb` service.

The format is `ServiceName.Namespace.mcm.svc`.  In this sample app the url is http://service-discovery3-catalog-service.service-discovery3-app-ns.mcm.svc:9090

<img src="images/84-configmap.png" >

#### 5. Channel

The typical Channel resource for MCM.

<img src="images/90-channel.png" >

#### 6. Placement

Placement rules defining the  clusters `d` and  `e`.  

<img src="images/91-placement.png" >


#### 7. Subscription

Subscriptions connecting the kubernetes resources `Deployment`, `Services` and `Routes`  defined for  clusters `d` and  `e`.  

<img src="images/92-subscription.png" >

#### 8. Namespace

The namespace `service-discovery3-chn-ns` would be created in MCM Hub, to store the all the Channel, app and subscription related MCM Specific informations.

The namespace `service-discovery3-app-ns` would be created in MCM Hub and in Managed Clusters, to store app related Kubernetics specific information.

<img src="images/93-namespace.png" >
