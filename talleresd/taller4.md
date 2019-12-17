# Talleres Quotas y Limites
[Talleres de Despliegue](../despliegue.md)

Para entender mejor las restricciones, es bueno conocer algunos conceptos y componentes básicos de Openshift sobre los cuales actúan estos límites. la recomendacion es comenzar a experimentar con restricciones y límites después de familiarizarse con Openshift.

A continuación se muestran los componentes de Openshift influenciados por las restricciones.



**Containers - Contenedores**
Las unidades básicas de las aplicaciones OpenShift se denominan contenedores. Las tecnologías de contenedor de Linux son mecanismos livianos para aislar procesos en ejecución de modo que se limitan a interactuar solo con sus recursos designados. Muchas instancias de aplicaciones pueden ejecutarse en contenedores en un único host sin visibilidad en los procesos, archivos, red, etc. de los demás. Por lo general, cada contenedor proporciona un servicio único (a menudo denominado "microservicio"), como un servidor web o una base de datos, aunque los contenedores se pueden usar para cargas de trabajo arbitrarias.


**Pods**
OpenShift aprovecha el concepto de Kubernetes de un pod, que es uno o más contenedores desplegados juntos, y la unidad de cómputo más pequeña que se puede definir, implementar y administrar.


**Namespaces - Projects**
Un espacio de nombres de Kubernetes proporciona un mecanismo para abarcar recursos en un clúster. En OpenShift, un proyecto es un espacio de nombres de Kubernetes con anotaciones adicionales.

Los espacios de nombres proporcionan un alcance único para:

* Recursos nombrados para evitar colisiones básicas de nombres.
* Autoridad de gestión delegada a usuarios de confianza.
* La capacidad de limitar el consumo de recursos de la comunidad.
* La mayoría de los objetos en el sistema tienen un ámbito de nombres, pero algunos están exceptuados y no tienen espacio de nombres, incluidos nodos y usuarios.

A Kubernetes namespace provides a mechanism to scope resources in a cluster. In OpenShift, a project is a Kubernetes namespace with additional annotations.

**Límites y restricciones de OpenShift**
Hay tres diferentes tipos de límites y restricciones disponibles en Openshift.
* Quotas - Cuotas
* Limit ranges - Rangos Límites
* Compute resources - Recursos de computo

**Cuotas**
Las cuotas son límites configurados por espacio de nombres o proyecto y actúan como límite superior para los recursos en ese espacio de nombres en particular. Básicamente define la capacidad del espacio de nombres. Por ejemplo, si la capacidad total que usamos en uno o cien pods no está dictada por la cuota, excepto cuando se configura un número máximo de pods.

Como la mayoría de las cosas en Openshift, puede configurar una cuota con un archivo de  configuración en yaml. Una configuración básica para una cuota se ve así:

```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
spec:
  hard:
    pods: "5"
    requests.cpu: "500m"
    requests.memory: 512Mi
    limits.cpu: "2"
    limits.memory: 2Gi
```
**Millicores**
La CPU se mide en unidades llamadas milicores. Cada nodo en el clúster determina la cantidad de cores de CPU en el nodo y luego multiplica ese valor por 1000 para expresar su capacidad total. Por ejemplo, si un nodo tiene 2 cores, la capacidad de la CPU del nodo se representará como 2000m. Si quisiera usar 1/10 de un solo core, lo representaría como 100m.

Esta cuota dice que el espacio de nombres puede tener un máximo de 5 pods, y/o un máximo de 2 cores y 2 Gb de memoria, el "reclamo" inicial que hacen los pods en este espacio de nombres es de 500 milicores y 512 Mb de memoria.

**Rango límite - Limit ranges**
Otro tipo de límite es el "rango límite". Un rango límite también se configura en un espacio de nombres, sin embargo, un rango límite define límites por pod y/o contenedor en ese espacio de nombres. Básicamente proporciona límites de CPU y memoria para contenedores y pods.

Nuevamente, la configuración de un rango límite también se realiza mediante una configuración yaml:

```
apiVersion: "v1"
kind: "LimitRange"
metadata:
  name: "resource-limits"
spec:
  limits:
    -
      type: "Pod"
      max:
        cpu: "2"
        memory: "1Gi"
      min:
        cpu: "200m"
        memory: "6Mi"
    -
      type: "Container"
      max:
        cpu: "2"
        memory: "1Gi"
      min:
        cpu: "100m"
        memory: "4Mi"
      default:
        cpu: "300m"
        memory: "200Mi"
      defaultRequest:
        cpu: "200m"
        memory: "100Mi"
```
Aquí podemos ver los límites de Pod y Contenedor. Estos límites definen el "rango" (de ahí el término rango límite) para cada contenedor de pod en el espacio de nombres. Entonces, en el ejemplo anterior, cada Pod en el espacio de nombres inicialmente reclamará 200 milicores y 6Mb de memoria y puede ejecutarse con un máximo de 1 GB de memoria y 2 núcleos de CPU. Los límites reales con los que se ejecuta el Pod o contenedor se pueden definir en la especificación Pod o Contenedor que descubriremos a continuación. Sin embargo, el rango límite define el rango de estos límites.

**Calcular recursos - Compute resources**
El último de los límites es probablemente el más fácil de entender, los recursos de cómputo se definen en el Pod o en la especificación del Contenedor, por ejemplo, en la configuración de despliegue o el controlador de replicación. Y defina los límites de CPU y memoria para ese pod en particular.

```
apiVersion: v1
kind: Pod
spec:
  containers:
  - image: nginx
    name: nginx
    resources:
      requests:
        cpu: 100m
        memory: 200Mi
      limits:
        cpu: 200m
        memory: 400Mi
```


En la especificación anterior, el Pod inicialmente reclamará 100 milicores y 200 Mb de memoria y alcanzará un máximo de 200 milicores y 400 Mb de memoria. Tenga en cuenta que siempre que se proporcione un rango de Límite en el espacio de nombres donde se ejecuta el Pod anterior y los límites de recursos de computo aquí están dentro del rango de límite, el Pod se ejecutará correctamente. Sin embargo, si los límites están por encima de los límites en el rango de límite, el pod no se iniciará.

## Taller de asignacion de recursos a los Pods


1. Ingrese a la terminal de la maquina bastion con su usuario de terminal
```
[localhost ~]$ ssh user0X@bastion.2775.example.opentlc.com
```


2. Garantice que esta logueado en el cluter de Openshift como su admin1
```
root@bastion ~]$ oc login -u admin1 https://loadbalancer.2775.internal:443
```

3. Valide los nodos del cluters y sus recursos
```
[user0X@bastion ~]$ oc get nodes
NAME                       STATUS    ROLES     AGE       VERSION
infranode1.2775.internal   Ready     infra     19h       v1.11.0+d4cacc0
infranode2.2775.internal   Ready     infra     19h       v1.11.0+d4cacc0
master1.2775.internal      Ready     master    19h       v1.11.0+d4cacc0
master2.2775.internal      Ready     master    19h       v1.11.0+d4cacc0
master3.2775.internal      Ready     master    19h       v1.11.0+d4cacc0
node1.2775.internal        Ready     compute   19h       v1.11.0+d4cacc0
node2.2775.internal        Ready     compute   19h       v1.11.0+d4cacc0
node3.2775.internal        Ready     compute   19h       v1.11.0+d4cacc0
```

Verifique los recursos usados por uno o todos los nodos de aplicaciones

```
[user0X@bastion ~]$ oc describe node node1.2775.internal | grep -A 4 Allocated
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource  Requests      Limits
  --------  --------      ------
  cpu       310m (15%)    220m (11%)

[user0X@bastion ~]$ oc describe node node2.2775.internal | grep -A 4 Allocated
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource  Requests      Limits
  --------  --------      ------
  cpu       310m (15%)    220m (11%)

[user0X@bastion ~]$ oc describe node node3.2775.internal | grep -A 4 Allocated
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource  Requests      Limits
  --------  --------      ------
  cpu       310m (15%)    220m (11%)
```


4. Cree un proyecto y una aplicacion

```
[user0X@bastion ~]$ oc new-project  limit-0X
Now using project "limit-0X" on server "https://loadbalancer.2775.internal:443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git

to build a new example application in Ruby.
[user0X@bastion ~]$ oc new-app php~https://github.com/jmanuelcalvo/app.git --name=app0X
```
5. Valide los recursos usados por esta aplicacion
```
[user0X@bastion ~]$ oc get pod -o wide
NAME            READY     STATUS      RESTARTS   AGE       IP           NODE                  NOMINATED NODE
app0X-1-7zktx   1/1       Running     0          18s       10.1.8.241   node3.2775.internal   <none>
app0X-1-build   0/1       Completed   0          45s       10.1.14.51   node1.2775.internal   <none>
```
Identifique en que nodo se enxuentra corriendo la aplicacion (en el ejemplo nodo3) y valida el uso de recursos nuevamente y comparelo con las salidas anteriores.

```
[user0X@bastion ~]$ oc describe node node3.2775.internal | grep -A 4 Allocated
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource  Requests      Limits
  --------  --------      ------
  cpu       1310m (65%)   1220m (61%)
  ```

4. Asignele unos limites especificos a este proyecto

```

[user0X@bastion ~]$ cat <<EOF > limits.yaml
apiVersion: "v1"
kind: "LimitRange"
metadata:
  name: "project-limits"
spec:
  limits:
  - type: "Pod"
    max:
      cpu: "500m"
      memory: "1Gi"
    min:
      cpu: "200m"
      memory: "100Mi"
  - type: "Container"
    default:
      cpu: "250m"
      memory: "512Mi"
EOF

[user0X@bastion ~]$ oc create -f limits.yaml
limitrange/dev-limits created
```

5. Verifique los limites creados en el proyexto

```
[user0X@bastion ~]$ oc get limitranges
NAME             CREATED AT
project-limits   2019-12-17T13:04:08Z

[user0X@bastion ~]$ oc describe limitranges project-limits
Name:       project-limits
Namespace:  limit-0X
Type        Resource  Min    Max   Default Request  Default Limit  Max Limit/Request Ratio
----        --------  ---    ---   ---------------  -------------  -----------------------
Pod         memory    100Mi  1Gi   -                -              -
Pod         cpu       200m   500m  -                -              -
Container   cpu       -      -     250m             250m           -
Container   memory    -      -     512Mi            512Mi          -
```

6. Asignar Cuotas a un proyectos
```
[user0X@bastion ~]$ cat <<EOF > quota.yml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: project-quota
spec:
  hard:
    cpu: "900m"
EOF

[user0X@bastion ~]$ oc create -f quota.yml
resourcequota/project-quota created

[user0X@bastion ~]$ oc describe quota
Name:       project-quota
Namespace:  limit-0X
Resource    Used  Hard
--------    ----  ----
cpu         0     900m

```

7. Cree una nueva aplicacion y valide los valores de los limites y las cuotas
```
[user0X@bastion ~]$ oc new-app php~https://github.com/jmanuelcalvo/app.git --name=app0X
--> Found image 8e01e80 (2 weeks old) in image stream "openshift/php" under tag "7.1" for "php"

    Apache 2.4 with PHP 7.1
...
...
[user0X@bastion ~]$ oc describe quota
Name:       project-quota
Namespace:  limit-0X
Resource    Used  Hard
--------    ----  ----
cpu         250m  900m
```


8. Escale el pod y valida su quota nuevamente
```
[user0X@bastion ~]$ oc scale --replicas=2 dc/app0X
deploymentconfig.apps.openshift.io/app0X scaled

[user0X@bastion ~]$ oc describe quota
Name:       project-quota
Namespace:  limit-0X
Resource    Used  Hard
--------    ----  ----
cpu         500m  900m   
```



9. Ahora escale a 4 pods e identifique que la quota se excedio

```
[user0X@bastion ~]$ oc scale --replicas=4 dc/app0X

[user0X@bastion ~]$ oc get pod
NAME            READY     STATUS      RESTARTS   AGE
app0X-1-9xjmf   1/1       Running     0          2m
app0X-1-bmzhd   1/1       Running     0          1m
app0X-1-build   0/1       Completed   0          3m
app0X-1-l4zbd   1/1       Running     0          3m

```

Unicamente si visualizan 3 pods y si visualizamos los eventos en el proyecto se puede encontrar un mensaje como el siguiente:

```
[user0X@bastion ~]$ oc get ev
11s         2m           8         app0X-1.15e12ab18debde0c          ReplicationController                                            Warning   FailedCreate                  replication-controller         (combined from similar events): Error creating: pods "app0X-1-25f69" is forbidden: exceeded quota: project-quota, requested: cpu=250m, used: cpu=750m, limited: cpu=900m

[user0X@bastion ~]$ oc describe node node3.2775.internal | grep limit-0X
  limit-0X                         app0X-1-l4zbd                  250m (12%)    250m (12%)  512Mi (6%)       512Mi (6%)

```



FUENTES:
https://www.rubix.nl/blogs/openshift-limits-explained/
