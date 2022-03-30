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

## Instalación y configuración

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

# Haproxy

# Estadísticas

# Go-between

# Pound

# Análisis comparativo

# Bibliografía

- https://www.cyberciti.biz/faq/systemd-systemctl-view-status-of-a-service-on-linux/
-