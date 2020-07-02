#Init oc
eval $(minishift oc-env)

#Login OS as admin
oc login -u admin -p admin

#Create new project
oc new-project tutorial

#Add policy - need to be able use istio sidecar
oc adm policy add-scc-to-user privileged -z default -n tutorial

#If need internal OS docker registry (instead of remote) to load container
eval $(minishift docker-env)
eval $(crc podman-env)

#Login internal Docker registry
docker login -u $(oc whoami) -p $(oc whoami -t) $(minishift openshift registry)
docker login -u kubeadmin -p $(oc whoami -t) default-route-openshift-image-registry.apps-crc.testing	

Create config maps with link to DB
oc apply -f test-rest-a/configmap.yml

#Print config maps
oc get cm

#Deploy MS B
mvn clean package
docker build -t tutorial/rest-app-b test-rest-b/.
docker tag tutorial/rest-app-b $(minishift openshift registry)/tutorial/rest-app-b
docker push $(minishift openshift registry)/tutorial/rest-app-b
oc delete deployment rest-app-b -n tutorial
#oc apply -f test-rest-b/deployment-rest-app-b.yml -n tutorial
istioctl kube-inject -f test-rest-b/deployment-rest-app-b.yml > test-rest-b/deployment-rest-app-b-istio.yml

# add privileged:true to istio-init container

oc apply -f test-rest-b/deployment-rest-app-b-istio.yml -n tutorial
oc get pods

#Deploy MS A
mvn clean package
docker build -t tutorial/rest-app-a test-rest-a/.
docker tag tutorial/rest-app-a $(minishift openshift registry)/tutorial/rest-app-a
docker push $(minishift openshift registry)/tutorial/rest-app-a
oc delete deployment rest-app-a -n tutorial
#oc apply -f test-rest-a/deployment-rest-app-a.yml -n tutorial
istioctl kube-inject -f test-rest-a/deployment-rest-app-a.yml > test-rest-a/deployment-rest-app-a-istio.yml

# add privileged:true to istio-init container

oc apply -f test-rest-a/deployment-rest-app-a-istio.yml -n tutorial
oc get pods

#Create and expose service for our MS to make it accessible for rest call
oc apply -f test-rest-a/service-a.yml -n tutorial

#expose service
oc expose service rest-app-a

#Create service for B
oc apply -f test-rest-b/service-b.yml -n tutorial

#expose service for B
oc expose service rest-app-b

#Call both services
curl http://rest-app-a-tutorial.192.168.42.33.nip.io/ping
curl http://rest-app-a-tutorial.192.168.42.33.nip.io/citiesCount
curl http://rest-app-b-tutorial.192.168.42.33.nip.io/ping














------------------------------------------------------------------------------------------------------------------------
istioctl authn tls-check $(oc get pods -n tutorial|grep rest-app-a|awk '{ print $1 }'|head -1) rest-app-a.tutorial.svc.cluster.local

# Sniff traffic between services
eval $(minishift oc-env)
export REST_APP_POD=$(oc get pod | grep rest-app-a | awk '{ print $1}' )
oc exec -it $REST_APP_POD -c istio-proxy /bin/bash
# Inside pod shell
ifconfig
### In the command below IP "172.17.0.23" is obtained from eth0 of "ifconfig" command
sudo tcpdump -vvvv -A -i eth0 '((dst port 8080) and (net 172.17.0.23))'


#To enable mTLS:

oc create -f istiofiles/authentication-enable-tls.yml -n tutorial
oc create -f istiofiles/destination-rule-tls.yml -n tutorial

#Disable mtls
oc replace -f istiofiles/disable-mtls.yml

#Create Ingress gateway
oc apply -f istiofiles/ingress-gateway.yaml
oc apply -f istiofiles/ingress-virtualService.yaml


#Compute Ingress Host and Port
#export INGRESS_HOST=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_HOST=$(minishift ip)
export INGRESS_PORT=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
echo $INGRESS_HOST:$INGRESS_PORT

curl -i -HHost:rest-app-a.example.com http://$INGRESS_HOST:$INGRESS_PORT/ping
curl -i -HHost:rest-app-a.example.com http://$INGRESS_HOST:$INGRESS_PORT/citiesCount



------------------------------------------------------------------------------------------------------------------------
#The following command shows an example to check the Envoy’s certificate for a pod.
kubectl exec [YOUR_POD] -c istio-proxy -n [YOUR_NAMESPACE] -- curl http://localhost:15000/certs | head -c 1000
###
{
 "certificates": [
  {
   "ca_cert": [
      ...
      "valid_from": "2019-06-06T03:24:43Z",
      "expiration_time": ...
   ],
   "cert_chain": [
    {
      ...
    }