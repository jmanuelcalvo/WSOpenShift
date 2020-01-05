[Talleres de Despliegue](../despliegue.md)

# Estrategias de despliegues avanzadas 
Las estrategias de despliegues proporcionan una forma para que la aplicación evolucione. Algunas estrategias utilizan la configuración de implementación para realizar cambios que los usuarios ven en todas las rutas que se resuelven en la aplicación. Otras estrategias, como las que se describen aquí, utilizan las funciones del enrutador para impactar rutas específicas.


## Implementación de Blue-Green 
Las implementaciones de blue-green implican ejecutar dos versiones de una aplicación al mismo tiempo y mover el tráfico de la versión en producción (la versión verde) a la versión más nueva (la versión azul). Puede usar una estrategia continua o cambiar servicios en una ruta. Dado que muchas aplicaciones dependen de datos persistentes, deberá tener una aplicación que admita la compatibilidad N-1, lo que significa que comparte datos e implementa la migración en vivo entre su base de datos, tienda o disco creando dos copias de su capa de datos. Considere los datos utilizados para probar la nueva versión. Si se trata de los datos de producción, un error en la nueva versión puede romper la versión de producción. Uso de una implementación azul-verde Las implementaciones azul-verde usan dos configuraciones de implementación. Ambos se están ejecutando y el que está en producción depende del servicio que especifica la ruta, con cada configuración de implementación expuesta a un servicio diferente. Puede crear una nueva ruta a la nueva versión y probarla. Cuando esté listo, cambie el servicio en la ruta de producción para que apunte al nuevo servicio y la nueva versión azul esté activa. Si es necesario, puede volver a la versión anterior, verde, cambiando el servicio a la versión anterior.

### Ejemplo
Cree dos copias de la aplicación de example:
```
$ oc new-app openshift/deployment-example:v1 --name=example-green
$ oc new-app openshift/deployment-example:v2 --name=example-blue
```

Esto crea dos componentes de aplicación independientes: uno que ejecuta la imagen v1 en el servicio de ejemplo verde y otro que usa la imagen v2 en el servicio de ejemplo azul.

Cree una ruta que apunte al servicio verde:
```
$ oc expose svc/example-green --name=bluegreen-example
```

Vaya a la aplicación en ejemplo-verde. <proyecto>. <dominio_rutador> para verificar que ve la imagen v1.
```
$ oc get route
```
Edite la ruta y cambie el nombre del servicio a example-blue:
```
$ oc patch route/bluegreen-example -p '{"spec":{"to":{"name":"example-blue"}}}'
```




## Despliegue A / B
La estrategia de implementación A / B le permite probar una nueva versión de la aplicación de forma limitada en el entorno de producción. Puede especificar que la versión de producción reciba la mayoría de las solicitudes de los usuarios, mientras que una fracción limitada de las solicitudes va a la nueva versión. Como controla la parte de las solicitudes para cada versión, a medida que avanzan las pruebas, puede aumentar la fracción de solicitudes a la nueva versión y, en última instancia, dejar de usar la versión anterior. A medida que ajusta la carga de solicitud en cada versión, es posible que también se deba escalar el número de pods en cada servicio para proporcionar el rendimiento esperado.

Además de actualizar el software, puede usar esta función para experimentar con versiones de la interfaz de usuario. Dado que algunos usuarios obtienen la versión anterior y algunos la nueva, puede evaluar la reacción del usuario a las diferentes versiones para informar las decisiones de diseño.

Para que esto sea efectivo, tanto la versión antigua como la nueva deben ser lo suficientemente similares como para que ambas puedan ejecutarse al mismo tiempo. Esto es común con las versiones de corrección de errores y cuando las nuevas características no interfieren con las antiguas. Las versiones necesitan compatibilidad N-1 para funcionar correctamente juntas.

Balanceo de carga para pruebas A/B
El usuario configura una ruta con múltiples servicios. Cada servicio maneja una versión de la aplicación.

A cada servicio se le asigna un peso y la parte de las solicitudes a cada servicio es el peso del servicio dividido por la suma de los pesos. El peso de cada servicio se distribuye a los puntos finales del servicio, de modo que la suma de los pesos del punto final es el peso del servicio.

La ruta puede tener hasta cuatro servicios. El peso para el servicio puede estar entre 0 y 256. Cuando el peso es 0, el servicio no participa en el equilibrio de carga pero continúa sirviendo conexiones persistentes existentes. Cuando el peso del servicio no es 0, cada punto final tiene un peso mínimo de 1. Debido a esto, un servicio con muchos puntos finales puede terminar con un peso mayor al deseado. En este caso, reduzca el número de cápsulas para obtener el peso de equilibrio de carga deseado. Consulte la sección Backends y pesos alternativos para obtener más información.
OpenShift Container Platform admite la compatibilidad N-1 a través de la consola web y la interfaz de línea de comandos

![Ref](talleresd/loadbalancingab.png)

### Ejemplo

Para configurar el entorno A/B:

Cree las dos aplicaciones y asígneles nombres diferentes. Cada uno crea una configuración de implementación. Las aplicaciones son versiones del mismo programa; una suele ser la versión de producción actual y la otra la nueva versión propuesta:
```
$ oc nueva-aplicación openshift / despliegue-ejemplo1 --nombre = ab-ejemplo-a
$ oc nueva aplicación openshift / despliegue-ejemplo2 --nombre = ab-ejemplo-b
```
Exponga la configuración de implementación para crear un servicio:
```
$ oc exponer dc / ab-example-a --name = ab-example-A
$ oc exponer dc / ab-example-b --name = ab-example-B
```
En este punto, ambas aplicaciones están implementadas, en ejecución y con servicios.

Haga que la aplicación esté disponible externamente a través de una ruta. Puede exponer cualquiera de los servicios en este punto, puede ser conveniente exponer la versión de producción actual y luego modificar la ruta para agregar la nueva versión.
```
$ oc exponer svc / ab-example-A
```

Edite el router y adicione los pesos (weight) para cada uno de los servicios
```
$ oc edit route <route-name>
...
metadata:
  name: route-alternate-service
  annotations:
    haproxy.router.openshift.io/balance: roundrobin
spec:
  host: ab-example.my-project.my-domain
  to:
    kind: Service
    name: ab-example-A
    weight: 10
  alternateBackends:
  - kind: Service
    name: ab-example-B
    weight: 15
...
```

Tambien puede cambiar los pesos de los servicios
```
$ oc set route-backends web ab-example-A=198 ab-example-B=2
```
Esto significa que el 99% del tráfico se enviará al servicio ab-ejemplo-A y el 1% al servicio ab-ejemplo-B

Puede visualizar por la linea de comandos los pesos para cada uno de los servicios
```
$ oc set route-backends web
NAME                    KIND     TO           WEIGHT
routes/web              Service  ab-example-A 198 (99%)
routes/web              Service  ab-example-B 2   (1%)
```


## Compatibilidad N-1
Las aplicaciones que tienen código nuevo y código antiguo ejecutándose al mismo tiempo deben tener cuidado para garantizar que los datos escritos por el nuevo código puedan ser leídos y manejados (o ignorados con gracia) por la versión anterior del código. Esto a veces se llama evolución del esquema y es un problema complejo.

Esto puede tomar muchas formas: datos almacenados en el disco, en una base de datos, en un caché temporal o que es parte de la sesión del navegador de un usuario. Si bien la mayoría de las aplicaciones web pueden admitir implementaciones continuas, es importante probar y diseñar su aplicación para manejarla.

Para algunas aplicaciones, el período de tiempo que el código antiguo y el código nuevo se ejecutan uno al lado del otro es corto, por lo que se aceptan errores o algunas transacciones fallidas del usuario. Para otros, el patrón de falla puede hacer que toda la aplicación deje de funcionar.

Una forma de validar la compatibilidad N-1 es usar una implementación A / B. Ejecute el código antiguo y el código nuevo al mismo tiempo de forma controlada en un entorno de prueba y verifique que el tráfico que fluye hacia la nueva implementación no cause fallas en la implementación anterior.




FUENTES:
https://docs.openshift.com/container-platform/3.11/dev_guide/deployments/advanced_deployment_strategies.html
