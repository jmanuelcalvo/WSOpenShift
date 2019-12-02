# Instalacion de Istio como Operador


Repository includes example custom resources in openshift-ansible/istio:

istio-installation-minimal.yaml: Minimal Red Hat OpenShift service mesh installation
istio-installation-kiali.yaml: Basic Red Hat OpenShift service mesh installation, including Kiali
istio-installation-full.yaml: Full Red Hat OpenShift service mesh installation, all features enabled

Examples must be customized before deployment

1. Clonar el proyecto:
```
git clone https://github.com/Maistra/openshift-ansible
```
2. Crear un nuevo proyecto istio-operator:
```
oc new-project istio-operator --display-name="Service Mesh Operator"
```
3. Crear el operator:
```
oc process -f $HOME/openshift-ansible/istio/istio_product_operator_template.yaml --param=OPENSHIFT_ISTIO_MASTER_PUBLIC_URL=$(oc whoami --show-server) | oc create -f -
```


# Componentes de Service Mesh
Pilot
Mixer
Envoy

# Traffic Management

Red Hat® OpenShift® service mesh traffic management decouples traffic flow and infrastructure scaling

Use Pilot to specify rules for traffic management between pods

Pilot and Envoy manage which pods receive traffic

Example: Service A calls Service B

Use Pilot to specify that you want:

95% of traffic routed to Service B, pods 1–3

5% of traffic routed to Service B, pod 4

![Ref](tm01.png)

