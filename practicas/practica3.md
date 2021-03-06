---
title: Balanceo de carga
author: Andrés Millán Muñoz (*amilmun@correo.ugr.es*)
keywords: [SWAP, servidores, servers, cloud computing, vm]
link-citations: true
date: \today

titlepage: true,
titlepage-color: "22a6b3"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "FFFFFF"
titlepage-rule-height: 2

book: true
classoption: [oneside]

toc: true
numbersections: true

header-left: "\\textcolor{gray}{\\thetitle}"
header-right: "Andrés Millán"
footer-left: "\\hspace{1cm}"
footer-center: "\\thepage"
footer-right: "\\hspace{1cm}"

colorlinks: true
linkcolor: RoyalBlue
urlcolor: RoyalBlue
---

<!-- LTeX: language=es -->

En esta práctica vamos a configurar un balanceador de carga para gestionar nuestras máquinas virtuales. Para ello, configuraremos una nueva VM, llamada `m3`, e instalaremos distintos tipos de software. Entre ellos, `nginx`, `haproxy`, ...

La máquina `m3` se ha instalado de manera similar a las dos anteriores, a excepción de que no se ha instalado Apache. Las IPs, por tanto, quedan así:

- **M1**: `192.168.49.128`.
- **M2**: `192.168.49.129`.
- **M3**: `192.168.49.130`.

# Nginx

## Instalación y configuración básica

Para instalar `nginx`, debemos poner el siguiente comando:

```bash
sudo apt-get install nginx
```

Podemos iniciar el servicio con

```bash
sudo systemctl start nginx
```

Se puede comprobar el estado del servicio con

```bash
systemctl status nginx
```

![Log con la instalación de `nginx`, activación del servicio y comprobación del estado](./img/3/nginx_status.png){ width=450px }

Para que actúe como balanceador, necesitamos deshabilitar la funcionalidad de servidor web. Para ello, editamos el archivo `/etc/nginx/nginx.conf`, comentado la línea

```bash
# include/etc/nginx/sites-enabled/*;
```

![](img/3/nginx_config.png){ width=450px }

Ahora debemos configurar el *upstream* con las direcciones de las máquinas virtuales. El archivo pertinente se encuentra en `/etc/nginx/conf.d/default.conf`, y debe tener el siguiente contenido:

```bash
upstream balanceo_amilmun {
    server ip_m1;
    server ip_m2;
}

server {
    # configuración del server. En particular, hay que hacer incapié en...
    server_name balanceador_amilmun;

    location {
        proxy_pass http://balanceo_amilmun;
    }
}
```

![](img/3/nginx_upstream.png){ width=450px }

Una vez se ha configurado el archivo, se reinicia el servicio con `sudo service nginx restart`. Si todo ha ido bien, no debería dar ningún error.

Usando curl desde el host, podemos comprobar que está funcionando:

![](img/3/curl_balanceador.png){ width=400px }

## Otros tipos de configuración

La configuración anterior utiliza round robin. Podemos cambiar a un balanceador de carga **con prioridad** usando el parámetro `weight` en `default.conf`:

```bash
upstream balanceo_amilmun {
    server ip_m1 weight = n1;
    server ip_m2 weight = n2;
}
```

Por ejemplo, si ponemos M1 con peso 2, y M2 con peso 1, quedaría de la siguiente forma:

![](./img/3/ponderacion.png){ width=450px }

Alternativamente, para usar un **balanceo por IP**, debemos indicar la directiva `ip_hash`:

```bash
upstream balanceo_amilmun {
    ip_hash;
    server ip_m1;
    server ip_m2;
}
```

![](./img/3/ip_hash.png){ width=450px }

Por último, podemos **mantener las conexiones activas** con `keepalive`. Para ello, usamos `keepalive {valor}`. Este `valor` limita el número de conexiones activas en idle almacenadas en cada máquina. Si se alcanza esta cifra, se cierra la conexión con la IP menos usada.

![](img/3/keepalive.png){ width=450px }

### Otros parámetros

Todos estos valores se pone tras la IP del servidor en el upstream:

- `weight = {valor}`: indica el peso en la ponderación de la máquina.
- `max_fails = {valor}`: indica el número de fallos que se pueden tener en la conexión de la máquina antes de que se cierre.
- `fail_timeout = {valor}`: indica el periodo máximo de tiempo que debe ocurrir para que entre en efecto `max_fails`. Su valor por defecto es 10s.
- `down`: indica que la máquina está caída. Está pensado para utilizarse con `ip_hash`.
- `backup`: indica que la máquina está pensada para ser un respaldo. Así, si el resto no está disponible por algún motivo, entra en efecto.

Un ejemplo de configuración final sería el siguiente:

![](./img/3/ngnix_config_varia.png){ width=450px }

# Haproxy

A continuación, instalaremos y configuraremos `haproxy`, de manera similar a `nginx`.

Antes de comenzar, debemos deshabilitar `nginx`, puesto que en caso contrario, ambos programas estarían luchando por el mismo puerto. Podemos conseguirlo con

```bash
sudo service nginx stop  # solo para esta sesión
sudo systemctl disable nginx
```

### Instalación y configuración básica

Para instalar `haproxy`, debemos escribir el siguiente comando:

```bash
sudo apt-get install haproxy
```

Habilitamos el servicio con

```bash
sudo systemctl start haproxy
# Alternativamente
sudo service haproxy start
```

![](./img/3/haproxy_instalacion.png){ width=450px }

El archivo de configuración se encuentra en `/etc/haproxy/haproxy.cfg`. Haremos una configuración muy similar a la de `nginx`. Para conseguirlo, debemos editar el archivo, escribiendo lo siguiente:

![](./img/3/haproxy_conf_basica.png){ width=450px }

De esta forma, hemos creado un frontend que recibe conexiones http desde el puerto 80, y se las manda al backend `balanceo_amilmun`. Este backend tiene dos máquinas (M1 y M2), soportando cada máquina un número máximo de conexiones (`maxconn`) de 32 usuarios.

Para comprobar que funciona corerctamente, podemos hacer `curl 192.168.49.130/swap.html`. Dado que la salida es la misma que la que tuvimos con `nginx`, omitiré el pantallazo.

### Haproxy con ponderación

Podemos configurar haproxy con ponderación usando el parámetro `weight {peso}`:

![](img/3/haproxy_ponderacion.png){ width=450px }

### Otras opciones de Haproxy

Como era de esperar, haproxy tiene muchas opciones diversas de configuración. En esta sección vamos a describir algunas de ellas; las que resulten más destacables.

- La clave `global` permite evitar la redundancia de código en el archivo de configuración. Se aplica tanto a backend como a frontend.
- La clave `defaults` tiene el mismo efecto, pero para los backends.
- Con respecto al backend:
  - Se puede seleccionar el tipo de balanceo con `balance {clave}`. Por defecto, se usa `roundrobin`.
  - Podemos inyectar una cookie utilizada por el balanceador para distribuir las solicitudes futuras al mismo server.

![](img/3/haproxy_avanzado.png){ width=450px }

# Estadísticas

Una de las ventajas que ofrece `haproxy` es la facilidad para habilitar las estadísticas del balanceador. Para conseguirlo, modificamos la configuración, dejándola de la siguiente manera:

![](./img/3/haproxy_stats.png){ width=450px }

Podemos acceder a la página desde el navegador entrando en `http://192.168.49.130:9999/stats`:

![](./img/3/stats_login.png)
![](./img/3/stats_webpage.png)

Algunas de las modificaciones interesantes que podemos hacer son las siguientes:

- Se puede añadir la clave `stats refresh 10s` al archivo de configuración para decirle que refresque cada 10 segundos.
- `stats admin if TRUE` hace un bypass del login. Podría ser útil para debuggear.
- El timeout por defecto es 10 s. Se puede cambiar con `stats timeout {n}s`.

La descripción de cada columna se puede hallar en [esta entrada del blog de Haproxy](https://www.haproxy.com/blog/exploring-the-haproxy-stats-page/). Resulta especialmente útil como manual.

![](img/3/stats_avanzado.png){ width=450px }

# Go-between

El siguiente balanceador que usaremos será `gobetween`.

Como antes, debemos deshabilitar cualquier otro balanceador que estuviera activo. En nuestro caso, ahora mismo es `haproxy`.

Debemos instalarlo [a mano](https://github.com/yyyar/gobetween/wiki/Installation):

```bash
mkdir gobetween
cd gobetween
curl -s https://api.github.com/repos/yyyar/gobetween/releases | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4 | head -n 1 | wget -i -
tar -zxvf *.tar.gz
nano config/gobetween.toml
sudo gobetween -c config/gobetween.toml
```

El archivo por defecto que viene está bastante completo. De hecho, tiene un ejemplo de tamaño considerable dentro del propio `.toml`.

Las que usaremos serán:

```toml
...
[metrics]
enabled = true
...

[servers]
[servers.balanceo_aamilmun]
bind = "192.168.49.130:80"
protocol = "tcp"
balance = "roundrobin"

max_connections = 10000
client_idle_timeout = "10m"
backend_idle_timeout = "10m"
backend_connection_timeout = "2s"

    [servers.balanceo_aamilmun.discovery]
    kind = "static"
    static_list = [
      "192.168.49.128:80 weight=2",
      "192.168.49.129:80 weight=1"
    ]

    [servers.balanceo_amilmun.healthcheck]
    fails = 1
    passes = 1
    interval = "2s"
    timeout = "1s"
    kind = "ping"
    ping_timeout_duration = "500ms"
```

![](img/3/gobetween.png){ width=450px }

- El peso se puede cambiar con `{url_server:puerto} weight={peso}`.
- `leastconn` obliga a gobetween a seleccionar el backend con menos conexiones.
- `max_connections = {valor}` dicta el número máximo de conexiones al servidor. Otros parámetros relacionados son `client_idle_timeout`, `backend_idle_timeout` y `backend_connection_timeout`.
- En el apartado `[servers.balanceo_amilmun.healthcheck]` se puede configurar parámetros similares al anterior. No entraré en detalle, puesto que viene en el código anterior bien puesto; y son muy similares a los del resto de balanceadores.

# Zevenet

Para instalar Zevenet debemos proceder de manera algo diferente. Esto no es un programa como tal; sino una distribución. Proporcionan una ISO o un contenedor Docker. Nosotros optaremos por la primera opción.

Es importante añadir las tarjetas de red antes de iniciar la instalación del sistema. De esta forma, Zevenet configurará correctamente la red. En la instalación, debemos marcar la tarjeta `eth1`:

![](img/3/zevenet_network.png){ width=450px }

Para la IP usaremos `192.168.49.131`. Aunque lo pondremos en el instalador, realmente, esto es irrelevante, puesto que luego lo configuraremos con netplan. El resto de parámetros tomarán el valor que viene por defecto. El hostname y la contraseña se ha configurado para ser los mismos que en el resto de máquinas.

![](img/3/zevenet_ip.png){ width=450px }

Una vez instalado, iniciamos sesión con usuario `root` y contraseña `Swap1234`.

![](img/3/zevenet.png){ width=450px }

Aplicamos el siguiente netplan:

![](img/3/zevenet_netplan.png){ width=450px }

Podemos configurar el balanceador accediendo desde el navegador a la página `https://192.168.49.131:444/`, usando los mismos credenciales del login del sistema:

![](img/3/zevenet_dashboard.png)

Para crear el balanceo, podemos irnos a LSLB -> Farms. Creamos una nueva granja, añadiendo los backend M1 y M2:

![](img/3/zevenet_1.png)
![](img/3/zevenet_2.png)

Con esto, el balanceador está funcionando. La persistencia del servicio se puede activar con la opción `persistence`:

![](img/3/zevenet_3.png)

# Pound

Pound es un servidor proxy reverso y balanceador de carga sencillo.

La instalación de este programa será algo diferente. Pound no se encuentra en los repositorios de Ubuntu server 18.04, pero podemos bajarnos directamente el archivo `.deb`:

```
sudo apt-get update && sudo apt-get upgrade
wget http://launchpadlibrarian.net/384724960/init-system-helpers_1.54_all.deb   # Requisito de Pound
wget http://archive.ubuntu.com/ubuntu/pool/universe/p/pound/pound_2.8-2_amd64.deb
sudo dpkg -i init-system-helpers_1.54_all.deb
sudo dpkg -i pound_2.8-2_amd64.deb
```

En el proceso hemos tenido que actualizar `init-system-helpers`, puesto que no cumplía el requisito de que la versión debe ser mayor o igual a 1.54.

El archivo de configuración se encuentra en `/etc/pound/pound.cfg`. Una configuración básica para nuestro escenario sería la siguiente:

![](img/3/pound_basica.png){ width=450px }

Para iniciarlo, primero modificamos el archivo `/etc/default/pound` poniendo `startup=1`. Luego, hacemos `systemctl restart pound.service`. Nos pide los credenciales, por lo que usamos nuestra contraseña del usuario (`Swap1234`).

Añadiendo el parámetro `Priority {valor entre 1 y 9}`, modificamos los pesos.

![](img/3/pound_priority.png){ width=450px }

Algunos parámetros interesantes que podemos modificar son...

- `Alive {valor (s)}`: es el periodo de tiempo que el servidor esperará a que el backend responda.
- `Client {valor (s)}`: es el periodo de tiempo que el servidor esperará a que el cliente responda. Pasado este tiempo, el servidor cortará la conexión.
- `TimeOut {valor (s)}`: periodo de tiemp que Pound esperará al BackEnd para una respuesta.
- Se puede configurar un backend de emergencia con `Emergency`. Este se activará cuando el resto falle. La configuración sería idéntica a la que hemos hecho con `BackEnd` (a excepción de las IPs).


# Análisis comparativo

Para comprobar cuál de todos los balanceadores que hemos instalado se comporta mejor, usaremos la herramienta `ab`. Ambas máquinas sirven el mismo contenido, que está basado en la página html que creamos en la práctica 1 y sincronizamos entre las dos máquinas con `rsync` en la práctica 2.

Desde el host, haremos `ab -l -n 10000 -c 10 -i http://192.168.49.130/swap.html`. Generaremos el archivo de resultados en csv usando el parámetro `-g {archivo.csv}`. Este csv está preparado para mostrar los tiempos de respuesta con gnuplot. Además, guardaremos el tiempo medio de peticiones por segundo de cada balanceador:

| Balanceador             | Peticiones por segundo |
|:------------------------|:-----------------------|
| **Ngnix** (rr)          | `2708.30`              |
| **Nginx** (weight)      | `2700.22`              |
| **Haproxy** (rr)        | `1547.38`              |
| **Haproxy** (weight)    | `1671.30`              |
| **Zevenet** (rr)        | Error                  |
| **Zevenet** (weight)    | Error                  |
| **Go-between** (rr)     | `1550.48`              |
| **Go-between** (weight) | `1537.70`              |
| **Pound** (rr)          | `1286.97`              |
| **Pound** (weight)      | `1247.06`              |

En general, **estos datos nos proporcionan un buen resumen** de cómo se comporta cada balanceador:

![](img/3/comparativa.png)

Hablaremos en profundidad sobre estos resultados en una sección posterior.

## Sobre Zevenet

No se ha podido hacer el benchmark de Zevenet. Cuando se ha intentado iniciar, sale un mensaje de error.

![](img/3/zevenet_error.png){ width=450px }

Mi sospecha es que se trata de un problema con la instalación del grub. Pero teniendo en cuenta que el causante de este fallo es un reinicio de la máquina, y esta es la quinta vez que he tenido que reinstalarla, no voy a considerar más este balanceador. Podría ser una combinación de la configuración de instalación, o de su uso con VMWare. En cualquier caso, es el único de los balanceadores que hemos instalado que ha producido tantos problemas. Ha sido una mala experiencia de usuario.

## Tiempos de respuesta

La opción que hemos habilitado a la hora de hacer el benchmark nos permite sacar unas gráficas sobre el tiempo de respuesta:

![](img/3/nginx_grafica.png)

![](./img/3/haproxy_grafica.png)

![](img/3/gobetween_grafica.png)

![](./img/3/pound_grafica.png)

Estas gráficas son, en mi opinión, bastante más útiles que las medias. Nos permitirán comparar más a fondo cada balanceador. Cada gráfica muestra el tiempo de respuesta requerido para cada petición, **ordenadas de menor a mayor**.

Por ejemplo, podemos ver que **Pound** ha tardado bastante más en procesar un 10% de las peticiones, siendo el percentil 1 particularmente elevado. Esto hace que la media se agrande considerablemente.

Por otro lado, **Nginx** mantiene un 80% de las respuestas por debajo de 5 ms, lo cual compensa el percentil 1.

Lo contrario ocurre con **Haproxy y Go-between**. Sus resultados son más consistentes, pero no mantienen una media especialmente baja.

Estas gráficas también nos permiten ver claramente que **no hay apenas diferencia entre roundrobin y ponderación**. Esto es razonable, pues las dos máquinas usadas son idénticas y sirven el mismo contenido. La única diferencia es la carga que son capaces de soportar, teniendo en cuenta que ambas utilizan el mismo hardware virtualizado.

## Sobre la fiabilidad de estos datos

Primero, dejemos claro cuál es el punto de esta sección: **no creo que estos datos sean de confianza**. Tampoco creo que sirvan para hacer un análisis justo.

A la hora de hacer pruebas, he notado que **el principal bottleneck es el host**. Se ha usado un portátil con un i5-8250U con 8 GB de RAM en un NVME SSD. Para sacar los resultados, se han de tener abiertas 3 máquinas virtuales, con un editor (VSCode, basado en Electron) y algún que otro programa. Esto hace que se sature la RAM, y entre la paginación de disco en juego. Eso afecta severamente al benchmark. Por ejemplo, en la primera ejecución de `ab`, se observaban tiempos de respuesta tan altos como `3` segundos, un valor absurdamente alto comparado con los `6` ms de media. Tras varias ejecuciones, estos valores desaparecían. Mi hipótesis es que las máquinas entraban en primer plano, y el OS ponía en reposo algún otro proceso innecesario.

Otro punto importante es la ausencia de solidez del experimento. No creo que un balanceador se pueda analizar basándonos en un par de máquinas en el backend. Estos programas suelen ser muy complejos y están preparados para escalas considerablemente mayores. En contrarpartida, este trabajo es de juguete. Aun así, esto es normal, pues nos encontramos en una asignatura de universidad y no en un ámbito profesional; lo cual hace que diferenciar entre roundrobin y ponderación pueda resultar muy difícil.

## Conclusión

Si tuviera que elegir un balanceador basándonos en lo realizado en este documento, **personalmente priorizaría la experiencia de usuario**.

Aunque Nginx claramente ha sido capaz de superar al resto de balanceadores en cuanto a peticiones por segundo, no sería capaz de juzgar cómo se comportaría en una hipotética escalada horizontal. Además, es un servicio preparado para servidores especialmente grandes. Quizás, un programa más compacto como Go-between o Haproxy funcionara mejor en mi caso.

En esencia, la conclusión es que **todos han cumplido su cometido con mayor o menor facilidad**. Destacan negativamente los problemas de Zevenet, que pueden ser debidos a un error por mi parte. Aun así, me parece que es importante documentar los problemas que se han producido, pues es un aspecto a considerar.

# Referencias

- https://www.cyberciti.biz/faq/systemd-systemctl-view-status-of-a-service-on-linux/
- https://linuxhint.com/what-is-keepalive-in-nginx/
- https://documentation.suse.com/smart/linux/html/reference-systemctl-enable-disable-services/index.html
- https://www.haproxy.com/blog/the-four-essential-sections-of-an-haproxy-configuration/#:~:text=There%20are%20four%20essential%20sections,routed%20to%20your%20backend%20servers.
- https://support.ptc.com/help/thingworx/platform/r9/es/index.html#page/ThingWorx/Help/ThingWorxHighAvailability/HAProxyExample.html
- https://www.haproxy.com/blog/exploring-the-haproxy-stats-page/
- https://cbonte.github.io/haproxy-dconv/1.7/configuration.html
- https://www.wikiwand.com/es/Pound_-_Servidor_Proxy_Reverso
- https://www.apsis.ch/pound.html
- https://www.tecmint.com/setting-up-pound-web-server-load-balancing-in-linux/
- https://help.ubuntu.com/community/Pound