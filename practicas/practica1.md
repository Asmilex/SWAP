---
title: Preparación de las herramientas de SWAP
author: Andrés Millán Muñoz
keywords: [SWAP, servidores, servers, cloud computing, vm]
link-citations: true
date: \today

titlepage: true,
titlepage-color: "3C9F53"
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

# Objetivos

En esta práctica instalaremos y configuraremos dos máquinas virtuales de Ubuntu Server mediante VMWare. En particular, pondremos a punto una instalación de Apache, PHP, MySQL, SSH; así como la interfaz de red necesaria para comunicar ambas máquinas con el host y entre ellas mismas.

Para ver que todo funciona correctamente, usaremos la herramienta `curl` con el fin de solicitar una pequeña página web específica de cada VM. De esa forma, comprobaremos que Apache está propiamente configurado.

# Arrancando la máquina virtual

Antes de comenzar, debemos instalar ambos sistemas en **VMWare**. Se intentó hacerlo en VirtualBox, pero un `Kernel panic - not syncing: Attempted to kill the idle task` no me permitía iniciarlo. ¿Quizás sea debido a que estoy en Windows 11 insiders, y no se lleva bien con VirtualBox? Como alternativa probé con Hyper-V, pero los 8GB de RAM de mi portátil no permitía iniciar la máquina.

Empecemos con la creación de las máquinas. Como el proceso es análogo, mostraremos únicamente fotos de la segunda máquina, la correspondiente a `m2-amilmun`.

El usuario será `amilmun`, y la contraseña será `Swap1234`, como se indica en el guion. Aparte de la distribución de teclado, puesto que utilizo ANSI y debo configurarla a *US international con teclas muertas*, no se cambia ningún parámetro por defecto.

![](img/1/vmw_1.png)
![](img/1/vmw_2.png)
![](img/1/vmw_3.png)
![](img/1/vmw_4.png)
![](img/1/vmw_5.png)
![](img/1/vmw_6.png)

# Programas básicos

## LAMP

En el instalador no figuraba la opción para instalar LAMP, así que [usaremos `tasksel`](https://ubuntu.com/server/docs/lamp-applications#:~:text=LAMP%20Applications-,Overview,Management%20Software%20such%20as%20phpMyAdmin.) para hacerlo ahora:

```bash
sudo apt-get install tasksel
sudo tasksel install lamp-server
```

Si hacemos `apache2 -v`, vemos que aparece la versión:

![](img/1/apache_1.png)

Podemos comprobar que se está ejecutando con `ps aux | grep apache`:

![](img/1/apache_2.png)

## cURL

**cURL está instalado por defecto**, así que no será necesario ponerlo a mano.

![](img/1/curl_v.png)

### Parámetros de cURL

#### Métodos de petición

Podemos especificar el tipo de petición que estamos haciendo con cURL. Por defecto, se utiliza `GET`. Si queremos utilizar otro tipo, podemos usar `-X` después del comando `curl`. Por ejemplo: `curl -X POST {url}`. Se puede mandar información gracias a `-d`. Al usarlo, no será necesario poner `-X POST`, [puesto que se infiere](https://daniel.haxx.se/blog/2015/09/11/unnecessary-use-of-curl-x/).

#### Redireccionando la salida

Por defecto, cURL escribe los contenidos a `stdout`. Este comportamiento se puede modificar usando `-o {archivo}`. Por ejemplo, si quisiéramos guardar [el resultaod de la salida] al conectarnos a  nuestras máquinas, podemos escribir

```
curl http://192.168.49.128/swap.html -o log_curl.txt
```

#### Especificar el puerto

Para [especificar el puerto](https://stackoverflow.com/questions/20434620/can-curl-make-a-connection-to-any-tcp-ports-not-just-http-https) que se utilizará en la conexión, podemos usar `curl http://example.com:puerto`.

#### JSON

Una de las utilidades principales de cURL es la posibilidad de [enviar y recibir datos](https://reqbin.com/req/c-dwjszac0/curl-post-json-example) en formato JSON.

Para recuperar un JSON, podemos usar el comando `curl -X GET -H "Content-Type: application/json"`.

Mientras que para mandarlo, utilizamos `-d` seguido del JSON que queramos adjuntar.

#### Cookies

Esta herramienta permite [añadir cookies](https://catonmat.net/cookbooks/curl/set-cookies) a las peticiones que hagamos. Para ello, basta con utilizar el parámetro `-b` o `--cookie`

```
curl -b '{nombre_cookie=valor}' {url}
```

Por ejemplo, si queremos mandarle la sesión activa a la dirección: `curl -b 'session=amilmun' https://localhost/...`.

Para añadir varias cookies en la misma orden, basta con poner `-b cookie` todas las veces que necesitemos.

Se pueden guardar las cookies en disco con la opción `-c nombre_archivo.txt`. De esta forma, podremos reutilizarlas usando `-b nombre_archivo.txt`

# Configurando la interfaz de red

Añadiremos un nuevo adaptador de red desde VMWare del tipo *host only*:

![](img/1/host_only.png)

Los planes de red se encuentran almacenados en `/etc/netplan`. Vamos a añadir un nuevo adaptador `host-only` y configurarlo para fijar las IPs. En m1, será `192.168.49.128`, mientras que en m2 `192.168.49.129`. Para ello, [ponemos lo siguiente](https://linuxconfig.org/how-to-configure-static-ip-address-on-ubuntu-18-04-bionic-beaver-linux):

![](img/1/netplan.png)

Vamos a crear dos páginas sencillas en las máquinas virtuales. Ponemos los siguientes archivos en `/var/www/html/swap.html`:

En m1:

```
<html>
<body>
<h1>Holaaa, soy M1!</h1>
</body>
</html>
```

Y en m2:


```
<html>
<body>
<h1>Soy M2 o/</h1>
</body>
</html>
```

Si desde el host hacemos `curl http://192.168.49.128/swap.html`, obtenemos

![](./img/1/curl.png)

# SSH

Vamos a conectar las dos máquinas mediante SSH. Para acceder desde M1 a M2, ponemos

```
ssh 192.168.121.131
```

Y obtenemos

![](img/1/ssh_1.png)

Si queremos loggearnos en las máquinas sin necesidad de poner la contraseña, tenemos que hacer lo siguiente:

1. Generar un nuevo par de claves SSH con `ssh-keygen`.
2. Modificar el archivo `/etc/ssh/sshd_config` poniendo `PermitRootLogin yes`.
3. Copiar la clave a la otra máquina con `ssh-copy-id`. En mi caso, para mandarla de M1 a M2, ponemos `ssh-copy-id amilmun@192.168.121.131`.

![](img/1/ssh_2.png)