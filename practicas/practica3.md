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
header-right: "\\author"
footer-left: "\\hspace{1cm}"
footer-center: "\\thepage"
footer-right: "\\hspace{1cm}"

colorlinks: true
linkcolor: RoyalBlue
urlcolor: RoyalBlue
---

<!-- LTeX: language=spanish -->

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

![Log con la instalación de `nginx`, activación del servicio y comprobación del estado](./img/3/nginx_status.png)

Para que actúe como balanceador, necesitamos deshabilitar la funcionalidad de servidor web. Para ello, editamos el archivo `/etc/nginx/nginx.conf`, comentado la línea

```bash
# include/etc/nginx/sites-enabled/*;
```

![](img/3/nginx_config.png)

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

![](img/3/nginx_upstream.png)

Una vez se ha configurado el archivo, se reinicia el servicio con `sudo service nginx restart`. Si todo ha ido bien, no debería dar ningún error.

Usando curl desde el host, podemos comprobar que está funcionando:

![](img/3/curl_balanceador.png)

## Otros tipos de configuración

La configuración anterior utiliza round robin. Podmeos cambiar a un balanceador de carga **con prioridad** usando el parámetro `weight` en `default.conf`:

```bash
upstream balanceo_amilmun {
    server ip_m1 weight = n1;
    server ip_m2 weight = n2;
}
```

Por ejemplo, si ponemos m1 con peso 2, y m2 con peso 1, quedaría de la siguiente forma:

![](./img/3/ponderacion.png)

Alternativamente, para usar un **balanceo por IP**, debemos indicar la directiva `ip_hash`:

```bash
upstream balanceo_amilmun {
    ip_hash;
    server ip_m1;
    server ip_m2;
}
```

![](./img/3/ip_hash.png)

Por último, podemos **mantener las conexiones activas** con `keepalive`. Para ello, usamos `keepalive {valor}`. Este `valor` limita el número de conexiones activas en idle almacenadas en cada máquina. Si se alcanza esta cifra, se cierra la conexión con la IP menos usada.

![](img/3/keepalive.png)

### Otros parámetros

Todos estos valores se pone tras la IP del servidor en el upstream:

- `weight = {valor}`: indica el peso en la ponderación de la máquina.
- `max_fails = {valor}`: indica el número de fallos que se pueden tener en la conexión de la máquina antes de que se cierre.
- `fail_timeout = {valor}`: indica el periodo máximo de tiempo que debe ocurrir para que entre en efecto `max_fails`. Su valor por defecto es 10s.
- `down`: indica que la máquina está caída. Está pensado para utilizarse con `ip_hash`.
- `backup`: indica que la máquina está pensada para ser un respaldo. Así, si el resto no está disponible por algún motivo, entra en efecto.

Un ejemplo de configuración final sería el siguiente:

![](./img/3/ngnix_config_varia.png)

# Haproxy

A continuación, instalaremos y configuraremos `haproxy`, de manera similar a `nginx`.

Antes de comenzar, debemos deshabilitar `nginx`, puesto que en caso contrario, ambos programas estarían luchando por el mismo puerto. Podemos conseguirlo con

```bash
sudo service nginx stop
```

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

![](./img/3/haproxy_instalacion.png)

El archivo de configuración se encuentra en `/etc/haproxy/haproxy.cfg`. Haremos una configuración muy similar a la de `nginx`. Para conseguirlo, debemos editar el archivo, escribiendo lo siguiente:

![](./img/3/haproxy_conf_basica.png)

De esta forma, hemos creado un frontend que recibe conexiones http desde el puerto 80, y se las manda al backend `balanceo_amilmun`. Este backend tiene dos máquinas (m1 y m2), soportando cada máquina un número máximo de conexiones (`maxconn`) de 32 usuarios.

Para comprobar que funciona corerctamente, podemos hacer `curl 192.168.49.130/swap.html`. Dado que la salida es la misma que la que tuvimos con `nginx`, omitiré el pantallazo.

# Estadísticas

Una de las ventajas que ofrece `haproxy` es la facilidad para habilitar las estadísticas del balanceador. Para conseguirlo, modificamos la configuración, dejándola de la siguiente manera:

![](./img/3/haproxy_stats.png)

Podemos acceder a la página desde el navegador entrando en `http://192.168.49.130:9999/stats`:

![](./img/3/stats_login.png)
![](./img/3/stats_webpage.png)


# Go-between

# Pound

# Análisis comparativo

# Bibliografía

- https://www.cyberciti.biz/faq/systemd-systemctl-view-status-of-a-service-on-linux/
- https://linuxhint.com/what-is-keepalive-in-nginx/