#!/bin/bash

echo 'Start OpenShift 4.3 services initialization!'
export M2_HOME=/Users/valery/apache-maven-3.6.3
export PATH=$PATH:$M2_HOME/bin

#Init oc
eval $(crc oc-env)

# Clear all
oc delete deployment rest-app-a -n tutorial
oc delete deployment rest-app-b -n tutorial

#Login OS as admin
oc login -u kubeadmin -p kKdPx-pjmWe-b3kuu-jeZm3 https://api.crc.testing:6443

#Create new project
oc new-project tutorial

#Add policy - need to be able use istio sidecar
oc adm policy add-scc-to-user privileged -z default -n tutorial

#If need internal OS registry (instead of remote) to load container
eval $(crc podman-env)

#OPENSHIFT_REGISTRY=default-route-openshift-image-registry.apps-crc.testing
OPENSHIFT_REGISTRY=default-route-openshift-image-registry.apps-crc.testing

#Login internal CRC registry
docker login -u kubeadmin -p $(oc whoami -t) default-route-openshift-image-registry.apps-crc.testing	

Create config maps with link to DB
oc apply -f test-rest-a/configmap.yml

#Print config maps
oc get cm

#Deploy MS B
mvn clean package
docker build -t tutorial/rest-app-b test-rest-b/.
docker tag tutorial/rest-app-b $OPENSHIFT_REGISTRY/tutorial/rest-app-b
docker push $OPENSHIFT_REGISTRY/tutorial/rest-app-b
oc delete deployment rest-app-b -n tutorial

#oc apply -f test-rest-b/deployment-rest-app-b.yml -n tutorial
#istioctl kube-inject -f test-rest-b/deployment-rest-app-b.yml > test-rest-b/deployment-rest-app-b-istio.yml

# add privileged:true to istio-init container

oc apply -f test-rest-b/deployment-rest-app-b.yml -n tutorial
echo 'Get pods of service B'

#Deploy MS A
mvn clean package
docker build -t tutorial/rest-app-a test-rest-a/.
docker tag tutorial/rest-app-a $OPENSHIFT_REGISTRY/tutorial/rest-app-a
docker push $OPENSHIFT_REGISTRY/tutorial/rest-app-a
oc delete deployment rest-app-a -n tutorial
#oc apply -f test-rest-a/deployment-rest-app-a.yml -n tutorial
#istioctl kube-inject -f test-rest-a/deployment-rest-app-a.yml > test-rest-a/deployment-rest-app-a-istio.yml

# add privileged:true to istio-init container

oc apply -f test-rest-a/deployment-rest-app-a.yml -n tutorial

#Create and expose service for our MS to make it accessible for rest call
oc apply -f test-rest-a/service-a.yml -n tutorial

#expose service
oc expose service rest-app-a

#Create service for B
oc apply -f test-rest-b/service-b.yml -n tutorial

#expose service for B
oc expose service rest-app-b

oc get pods -n tutorial





------------------------------------------------------------------------------------------------------------------------
#istioctl authn tls-check $(oc get pods -n tutorial|grep rest-app-a|awk '{ print $1 }'|head -1) rest-app-a.tutorial.svc.cluster.local

## Sniff traffic between services
#eval $(crc oc-env)
#export REST_APP_POD=$(oc get pod | grep rest-app-a | awk '{ print $1}' )
#oc exec -it $REST_APP_POD -c istio-proxy /bin/bash
## Inside pod shell
#ifconfig
#### In the command below IP "172.17.0.23" is obtained from eth0 of "ifconfig" command
#sudo tcpdump -vvvv -A -i eth0 '((dst port 8080) and (net 172.17.0.23))'


#To enable mTLS:

#oc create -f istiofiles/authentication-enable-tls.yml -n tutorial
#oc create -f istiofiles/destination-rule-tls.yml -n tutorial

#Disable mtls
#oc replace -f istiofiles/disable-mtls.yml

#Create Ingress gateway
#oc apply -f istiofiles/ingress-gateway.yaml
#oc apply -f istiofiles/ingress-virtualService.yaml


##Compute Ingress Host and Port
##export INGRESS_HOST=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
#export INGRESS_HOST=$(minishift ip)
#export INGRESS_PORT=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
#export SECURE_INGRESS_PORT=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
#echo $INGRESS_HOST:$INGRESS_PORT
#
#curl -i -HHost:rest-app-a.example.com http://$INGRESS_HOST:$INGRESS_PORT/ping
#curl -i -HHost:rest-app-a.example.com http://$INGRESS_HOST:$INGRESS_PORT/citiesCount



------------------------------------------------------------------------------------------------------------------------
##The following command shows an example to check the Envoy’s certificate for a pod.
#kubectl exec [YOUR_POD] -c istio-proxy -n [YOUR_NAMESPACE] -- curl http://localhost:15000/certs | head -c 1000
####
#{
# "certificates": [
#  {
#   "ca_cert": [
#      ...
#      "valid_from": "2019-06-06T03:24:43Z",
#      "expiration_time": ...
#   ],
#   "cert_chain": [
#    {
#      ...
#    }

echo 'Finish configuration'
echo 'Start validation checks'
istioctl authn tls-check $(oc get pods -n tutorial|grep rest-app-a|awk '{ print $1 }'|head -1) rest-app-a.tutorial.svc.cluster.local

sleep 2s
echo 'Create Ingress gateway'
oc apply -f istiofiles/ingress-gateway.yaml
oc apply -f istiofiles/ingress-virtualService.yaml

#export INGRESS_HOST=$(crc ip)
#export INGRESS_PORT=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
#export SECURE_INGRESS_PORT=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
#echo $INGRESS_HOST:$INGRESS_PORT
#
#curl -i -HHost:rest-app-a.example.com http://$INGRESS_HOST:$INGRESS_PORT/ping
#
#
#curl -i -HHost:rest-app-a-tutorial.apps-crc.testing http://rest-app-a-tutorial.apps-crc.testing/citiesCount
#
#
##curl -i -HHost:rest-app-a.example.com http://rest-app-a-tutorial.apps-crc.testing/ping
#
#
#curl -i -HHost:rest-app-a.example.com http://192.168.64.2:31037/ping


# Change sidecars log level
# istioctl proxy-config log POD --level=debug
# istioctl pc clusters istio-ingressgateway-5b59bb5f89-jx2z6 -n istio-system

# while (true); do curl -i http://istio-ingressgateway-istio-system.apps-crc.testing/citiesCount; sleep 1s; done

# istioctl x authz check POD


# ---------------- Egress traffic --------------------------------------
# curl kubernetes.docker.internal:8080/ext/ping

# Для доступа из кластера OS к сервису на хостовой тачке нужно найти IP интерфейса en0
ifconfig en0 | grep 'inet '

# !!! НЕ СРАБОТАЛО - Для доступа из кластера OS к сервису на хостовой тачке нужноп получить IP hyperkit на MacOS
#cat /var/db/dhcpd_leases

# Проверяем что доступ наружу есть
curl http://192.168.1.108:8080/ping
# pong
# Запрещаем весь трафик наружу кластера
# Run the following command to change the global.outboundTrafficPolicy.mode option to REGISTRY_ONLY:
oc get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | oc replace -n istio-system -f -
# oc get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | oc replace -n istio-system -f -
# Дожидаемся записи - configmap "istio" replaced
# Проверяем что доступа больше нет
curl -i -HHost:ext.tutorial.example.com http://192.168.1.108:8080/ping
curl -i -HHost:ext.tutorial.example.com http://ext.tutorial.example.com:8080/ping
#HTTP/1.1 502 Bad Gateway

# ServiceEntry to allow access to an external HTTP service:
oc apply -f egress-ServiceEntry.yaml



----------------------
docker build -t tutorial/rest-app-b test-rest-b/.
docker tag tutorial/rest-app-b $OPENSHIFT_REGISTRY/tutorial/rest-app-b
docker push $OPENSHIFT_REGISTRY/tutorial/rest-app-b


