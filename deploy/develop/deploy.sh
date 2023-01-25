#!/bin/bash
#########################################################################################################
# Desplegar la imagen docker de SelfWeb + nginx en máquina nueva, o bien actualizar
# en maquina existente.
# Este shell se ejecuta remotamente, una vez copiado a la maquina remota, en un directorio de trabajo,
# por lo que hemos de cuidar cómo nos movemos por los diferentes directorios.
#
# @arg  -s  (obligatorio) Nombre del servicio docker en el que debemos definir/actualizar la imagen.
# @arg  -i  (obligatorio) Id completo de la imagen docker a instalar/actualizar (incluyendo URL del registry).
# @arg  -n  (opcional) Nombre de la maquina virtual, si la hemos creando para este proyecto.
# @arg  -d  (opcional) Directorio de instalacion del proyecto. Por defecto /home/apps/<svc_name>
#
# Vers  Por Fecha      Notas
# ----- --- ---------- ----------------------------------------------------------------------------------
# 1.0.1 FNG 11/09/2022 Version inicial
#
#########################################################################################################

#########################################################################################################
function usage() {
    echo "Usage: deploy.sh -s <svc_docker> -i <docker_image> -u <gitlab_ user> -p <gitlab_passwd> -r <registry_url> [-n <nombre_maquina>] [-d <proy_dir>]"
    exit 1
}
#########################################################################################################

#########################################################################################################
# Cambiar nombre del host, si es necesario
#########################################################################################################
function change_hostname() {
    [[ -z $1 ]] && { echo "INFO change_hostname(): No nos han pasado nombre del host. Se ignora"; return 0; }
    [[ $1 == $(hostname) ]] && { echo "INFO change_hostname(): El nombre del host ya es '$1'. Se ignora"; return 0; }
    echo "INFO cambiando el nombre del host a '$1'.."
    # En Centos, Redhat y AmazonLinux hay que usar hostnamectl, en Alpine cambiamos /etc/hostname
    sudo hostnamectl set-hostname $1 || sudo echo "$1" > /etc/hostname
    [[ $? != 0 ]] && { echo "ERROR No se ha podido actualizar /etc/hostname"; exit 3; }
    sudo hostname $1
    [[ $? != 0 ]] && { echo "ERROR No se ha podido modificar el hostname"; exit 3; }
}

#########################################################################################################
# Detener el stack docker
#########################################################################################################
function docker_down() {
    if [[ -z $(docker ps -q -f "name=${SVC_NAME}") ]]; then
        echo "INFO El stack docker no esta iniciado"
    else
        echo "INFO Deteniendo el stack docker.."
        # V 1.0.3 se ha simplificado
        # docker-compose -f ${PRJ_DIR}/docker-compose.yml -f ${PRJ_DIR}/docker-compose.override.yml down
        docker-compose -f ${PRJ_DIR}/docker-compose.yml down
        [[ $? != 0 ]] && { echo "ERROR No se ha podido detener el stack docker"; exit 4; }
    fi
}

#########################################################################################################
# Arrancar el stack docker
#########################################################################################################
function docker_up() {
	# Antes que nada, hacer login al registro docker
	# excepto si es docker hub, que es un directorio publico
	if [[ $REGISTRY_URL == "dockerhub" ]]; then
    	echo "INFO El registry docker hub no requiere login"
	else
        echo "INFO Haciendo login al registro docker.."
		docker login -u $REGISTRY_USER -p $REGISTRY_PASSWD $REGISTRY_URL
    	[[ $? != 0 ]] && { echo "ERROR No se ha podido hacer login al registro docker"; exit 4; }
	fi
	# MODALIDAD 1:
	#
    # Crear/actualizar docker-compose.override.yml y lanzar stack con este archivo
    #echo "INFO Creando 'docker-compose.override.yml'.."
    #echo 'version: "3.7"' > ${PRJ_DIR}/docker-compose.override.yml
    #echo "services:" >> ${PRJ_DIR}/docker-compose.override.yml
    #echo "    ${SVC_NAME}:" >> ${PRJ_DIR}/docker-compose.override.yml
    #echo "        image: ${IMG_TAG}" >> ${PRJ_DIR}/docker-compose.override.yml
    #echo "INFO Iniciando stack docker.."
    #docker-compose -f ${PRJ_DIR}/docker-compose.yml -f ${PRJ_DIR}/docker-compose.override.yml up -d
    #
    # MODALIDAD 2:
    # Usamos sed para actualizar insitu el docker-compose.yml
    # Como sed es un poco enrevesado, lo explico: supongamos que el servicio  es "selfweb" y la
    # imagen que queremos montar es "unaimagen". El comando quedaria asi:    
    #   sed -i '/selfweb:/,/image:/ s@image:.*@image: unaimagen@' ${PRJ_DIR}/docker-compose.yml
    # sed hace lo siguiente:
    # 	- busca la primera ocurrencia de "selfweb:" y a partir de ella la primrera ocurrencia de "image:"
    #   - Sustituye en texto image:(y cualquier caracter hasta fin de linea) por el nuevo texto.
    #   - Como el nombre de la imagen puede contener caracteres "/", en la sustitucion usamos "@" como separador.
    #   - Como hemos usado la opcion -i hace el cambio insitu en el archivo.
    #
    sed -i '/'${SVC_NAME}':/,/image:/ s@image:.*@image: '${IMG_TAG}'@' ${PRJ_DIR}/docker-compose.yml
    docker-compose -f ${PRJ_DIR}/docker-compose.yml up -d
    [[ $? != 0 ]] && { echo "ERROR No se ha podido iniciar el stack docker"; exit 4; }
}

#########################################################################################################
# Crear volumenes docker
#########################################################################################################
function create_docker_volumes() {
    echo "INFO Creando volumenes nuevos.."
    local vol
    for vol in $(ls -C1 volumes); do
        if ! [[ -z $(docker volume ls -q -f "name=${vol}") ]]; then
            echo "INFO volumen ${vol} ya existe, se ignora"
            continue
        fi
        echo "INFO Creando volumen ${vol}.."
        docker volume create ${vol}
        [[ $? != 0 ]] && { echo "ERROR no se ha podido crear el volumen"; exit 3; }
    done
}

#########################################################################################################
# Crear networks docker
# PENDIENTE: Por ahora creamos networks tipo bridge sin ninguna caracteristica especial. Si se quieren
# hacer cosas más sofisticadas, dentro de cada directorio debajo de networks se podria guardar el
# comando completo y ejecutarlo aqui, o algo similar.
#########################################################################################################
function create_docker_networks() {
    echo "INFO Creando networks nuevos.."
    local net
    for net in $(ls -C1 networks); do
        if ! [[ -z $(docker network ls -q -f "name=${net}") ]]; then
            echo "INFO network ${net} ya existe, se ignora"
            continue
        fi
        echo "INFO Creando network ${net}.."
        docker network create -d bridge ${net}
        [[ $? != 0 ]] && { echo "ERROR no se ha podido crear el network ${net}"; exit 3; }
    done
}

#########################################################################################################
# Copiar el contenido de los diferentes volumenes a su destino bajo /var/lib/docker/volumes,
# eliminando previamente el contenido anterior, para dejarlo todo limpito. 
#########################################################################################################
function copy_volume_data() {
    local vol
    local dire
    local fich
    echo "INFO Copiando datos a volumenes docker.."
    for vol in $(ls -C1 volumes); do
        #
        # Este es el destino habitual de docker en linux, salvo que cambie en proximas versiones.
        # Para poder eliminar el contenido anterior y copiar el nuevo, hay que hacerlo con sudo.
        #
        dire="/var/lib/docker/volumes/${vol}/_data"
    	#
    	# Si el origen esta vacio, se ignora
    	#
        if [[ -z $(ls -A volumes/${vol}) ]]; then 
            echo "INFO El volumen ${vol} esta vacio, se ignora"
            continue 
        fi
        #
        # Si contiene un fichero testigo llamado 'ignore' paso de el (normalmente son volumenes para logs)
        #               
        if [[ -f volumes/${vol}/ignore ]]; then 
            echo "INFO El volumen ${vol} contiene un archivo 'ignore', se ignora"
            continue 
        fi 
        #
        # V 1.0.3
        # Si contiene un archivo llamado "only_if_new", sólo debemos copiar
        # si es instalacion nueva. Por ejemplo, si son los datos de base para
        # una BBDD. En primera instalación se copian, pero en actualizaciones no.              
        #
        if [[ -f volumes/${vol}/only_if_new && ! -z $(sudo ls -A ${dire}) ]]; then
            echo "INFO El volumen ${vol} contiene un archivo 'only_if_new' y el destino no esta vacio, se ignora"
            continue 
        fi
        # V 1.0.3 Si hay algun archivo tgz, lo extraemos insitu y lo eliminamos
        #
        for fich in $(ls -C1 volumes/${vol}); do
        	if [[ $fich == *".tgz" ]]; then
        	    echo "INFO Extrayendo ${vol}/${fich}.."
        		tar xzf volumes/${vol}/${fich} -C volumes/${vol}/
        	    echo "INFO Eliminando ${vol}/${fich} antes de copiar volumen.."
        		rm -f volumes/${vol}/${fich}
        	fi
        done
        echo "INFO Copiando volumen ${vol} a ${dire}.."
        sudo rm -Rf ${dire}/*
        [[ $? != 0 ]] && { echo "ERROR No se ha podido borrar el contenido anterior de ${dire}"; exit 4; }
        sudo cp -R volumes/${vol}/* ${dire}
        [[ $? != 0 ]] && { echo "ERROR No se ha podido copiar el contenido de '${vol}' a '${dire}'"; exit 4; }
    done
}

#########################################################################################################
#########################################################################################################
# MAIN
#########################################################################################################
#########################################################################################################

# Directorio en el que vive esta shell (estamos en la VM que hemos creado). Este directorio se habrá
# creado y populado previamente mediante un script de sftp.
# WORK_DIR seria algo asi como /<ci_project_path>/deploy

# Esto me da el path completo de esta shell (no funciona en ubuntu, pero si en alpine y en centos)
yo=$(realpath $0)
# Con esto me quedo solo con el directorio en el que vivo
WORK_DIR=$(dirname $yo)
echo "INFO El directorio de la shell es: $WORK_DIR"

# Parsear parametros
[[ $# < 1 ]] && usage

while getopts ":n:d:s:i:u:p:r:" parametro; do
    case ${parametro} in
        s)
            SVC_NAME=${OPTARG}
            ;;
        i)
            IMG_TAG=${OPTARG}
            ;;
        u)
        	REGISTRY_USER=${OPTARG}
        	;;
        p)
        	REGISTRY_PASSWD=${OPTARG}
        	;;
        r)
        	REGISTRY_URL=${OPTARG}
        	;;
        n)	
            VM_NAME=${OPTARG}
            ;;
        d)
            PRJ_DIR=${OPTARG}
            ;;
        :)
            echo "ERROR -${OPTARG} requiere un valor"
            usage
            ;;
        *)
            echo "ERROR -${OPTARG} no es una opcion valida"
            usage
            ;;
    esac
done

# Argumentos correctos? Valores por defecto?
[[ -z $SVC_NAME ]] && { echo "ERROR Argumento -s es obligatorio"; usage; }
[[ -z $IMG_TAG ]] && { echo "ERROR Argumento -i es obligatorio"; usage; }
[[ -z $REGISTRY_USER ]] && { echo "ERROR Argumento -u es obligatorio"; usage; }
[[ -z $REGISTRY_PASSWD ]] && { echo "ERROR Argumento -p es obligatorio"; usage; }
[[ -z $REGISTRY_URL ]] && { echo "ERROR Argumento -r es obligatorio"; usage; }
[[ -z $PRJ_DIR ]] && PRJ_DIR="/home/apps/${SVC_NAME}"

# DEBUG
echo "WORK_DIR     : $WORK_DIR"
echo "PRJ_DIR      : $PRJ_DIR"
echo "SVC_NAME     : $SVC_NAME"
echo "IMG_TAG      : $IMG_TAG"
echo "VM_NAME      : $VM_NAME"
echo "REGISTRY_URL : $REGISTRY_URL"

# Existe el directorio del proyecto ?
[[ -d ${PRJ_DIR} ]] || { echo "ERROR el directorio ${PRJ_DIR} no existe"; exit 2; }

# A partir de ahora, nos vamos al directorio de trabajo
cd ${WORK_DIR}

# Cambiar nombre del host, si es necesario
if ! [[ -z ${VM_NAME} ]]; then
    change_hostname ${VM_NAME}
fi

# Es una instalacion nueva, o ya existía?
if [[ -f ${PRJ_DIR}/docker-compose.yml ]]; then
	echo "INFO Instalación existente. Detenemos stack docker.."
    docker_down
fi

# Actualizamos el docker-compose
cp -f docker-compose.yml ${PRJ_DIR}

# Sea nueva o no, comprobamos los volumenes y networks, y los creamos si es necesario
create_docker_volumes
create_docker_networks

# Ya tenemos creados los volumenes. Tenemos que eliminar el contenido actual y copiar el nuevo
copy_volume_data

# Si todo ha ido bien, creamos el nuevo docker-compose.override.yml y arrancamos el stack
docker_up

# Por ultimo, mostramos los containers arrancados
docker ps
exit 0 

################################################# EOF ####################################################
