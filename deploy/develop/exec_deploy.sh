#!/bin/bash
##################################################################
# Funcion para despliegue de SelfWeb.
# En este ejemplo, usamos solamente bash y ssh, pero podriamos
# usar Ansible o cualquier otra herramienta.
##################################################################
function exec_deploy() {
    #
    # Solo si es un proyecto Docker
    #
    t_echo "Preparando deploy..."
    [[ ${IS_DOCKER_PRJ} != "true" ]] && { echo "WARN: No es un proyecto Docker. Esta etapa no se ejecuta."; exit 0; }
    #
    # DOCKER_IMG_TAG es una variable de entorno generada en la etapa 'prepare'. Si no existe, hay algo mal.
    #
    [[ -z ${DOCKER_IMG_TAG} ]] && { echo "ERROR: No existe la variable DOCKER_IMG_TAG. Parece que no se ha ejecutado la etapa 'prepare'"; exit 2; }
    #
    # Cargar variables desde cache 
    #
    t_echo "Cargando variables de entorno desde cicd.vars:"
    env_cicd_vars
    echo "--------------------------"
    cat cicd.vars
    echo "--------------------------"
    #
    # La IP remota debería estar configurada en cicd.vars por una ejecucion previa de tf_apply.
    # PENDIENTE: En proyectos en los que nunca se ejecute la etapa de provisionado, necesitamos
    # algun mecanismo para definir datos basicos del deploy, como la IP del destino, etc. En este
    # ejemplo, la etapa tf_apply ha guardado en cicd.vars la IP de la maqueina creada, como hyperv_instance_ip
    #
    ADDR=${hyperv_instance_ip}
    [[ -z $ADDR ]] && { echo "ERROR: No se ha encontrado la IP remota"; exit 3; }
  	# Usuario/passwd del registry, por defecto el del propio gitlab
  	[[ -z $CICD_REGISTRY_USER ]] && CICD_REGISTRY_USER=$CICD_USER
  	[[ -z $CICD_REGISTRY_PASSWD ]] && CICD_REGISTRY_PASSWD=$CICD_PASSWD
    #
    # Usamos como nombre del host el que nos han definido desde terraform
    #
    DEPLOY_HOST_NAME=${hyperv_host_name}
    #
    # DEBUG
    #
    t_echo "IS_DOCKER_PRJ      : ${IS_DOCKER_PRJ}"
    t_echo "DOCKER_IMG_TAG     : ${DOCKER_IMG_TAG}"
    t_echo "ADDR               : $ADDR"
    t_echo "DEPLOY_HOST_NAME   : $DEPLOY_HOST_NAME"
    t_echo "DEPLOY_SSH_PATH    : ${DEPLOY_SSH_PATH}"
    t_echo "DEPLOY_SSH_SVC_NAME: ${DEPLOY_SSH_SVC_NAME}"
    #
    # Cadena de conexion a la VM
    #
    CONN_STRING="${DEPLOY_SSH_USER}@${ADDR}"
    #
    # Si es la primera vez que hacemos deploy de este proyecto en esta maquina, tenemos que crear el
    # directorio del proyecto. Como en sftp el comando mkdir no tiene la opcion -p, hay que hacerlo
    # mediante ssh. Ademas, y por si estamos haciendo un update, eliminamos el directorio de trabajo anterior.
    #
    t_echo "----------------------------------------------------------------------------------------"
    t_echo "INFO Preparando el directorio destino en la maquina remota.."
    t_echo "----------------------------------------------------------------------------------------"
    ret=0
    COMANDO="sudo mkdir -p ${DEPLOY_SSH_PATH}; \
    sudo chown ${DEPLOY_SSH_USER} ${DEPLOY_SSH_PATH}; \
    sudo chgrp ${DEPLOY_SSH_USER} ${DEPLOY_SSH_PATH}; \
    rm -Rf ${DEPLOY_SSH_PATH}/work"
    ssh -o StrictHostKeyChecking=no -i ${DEPLOY_SSH_KEY} ${CONN_STRING} ${COMANDO}
    [[ $? != 0 ]] && { echo "ERROR No se ha podido ejecutar la fase de preparacion."; exit 1; }
    t_echo "----------------------------------------------------------------------------------------"
    t_echo "INFO Ejecutando sftp para subir el directorio deploy a la maquina remota.."
    t_echo "----------------------------------------------------------------------------------------"
    sftp -o StrictHostKeyChecking=no -i ${DEPLOY_SSH_KEY} -r ${CONN_STRING} << ***EndOfFile***
    put -p ${DEPLOY_ROOT} ${DEPLOY_SSH_PATH}/work
***EndOfFile***

    #scp -r -o StrictHostKeyChecking=no -i ${DEPLOY_SSH_KEY} ${DEPLOY_ROOT} ${CONN_STRING}:${DEPLOY_SSH_PATH}/work
    [[ $? != 0 ]] && { echo "ERROR sftp no se ha ejecutado correctamente"; exit 1; }
    #
    # Ejecutamos en remoto el comando de deploy que hemos subido como parte del directorio de trabajo.
    #
    COMANDO="chmod 755 ${DEPLOY_SSH_PATH}/work/deploy.sh && \
    ${DEPLOY_SSH_PATH}/work/deploy.sh \
    -s ${DEPLOY_SSH_SVC_NAME} \
    -i ${DOCKER_IMG_TAG} \
    -u ${CICD_REGISTRY_USER} \
    -p ${CICD_REGISTRY_PASSWD} \
    -r ${CICD_REGISTRY_HOST} \
    -d ${DEPLOY_SSH_PATH} \
    -n ${DEPLOY_HOST_NAME} \
    > ${DEPLOY_SSH_PATH}/work/deploy.log 2>&1"
    t_echo "----------------------------------------------------------------------------------------"
    t_echo "INFO Ejecutando script remoto deploy.sh"
    t_echo "----------------------------------------------------------------------------------------"
    ret=0
    ssh -o StrictHostKeyChecking=no -i ${DEPLOY_SSH_KEY} ${CONN_STRING} "${COMANDO}" || ret=$? 
    t_echo "INFO El codigo de retorno del script ha sido: $ret"
    t_echo "----------------------------------------------------------------------------------------"
    t_echo "INFO Descargando log del script.."
    t_echo "----------------------------------------------------------------------------------------"
    sftp -o StrictHostKeyChecking=no -i ${DEPLOY_SSH_KEY} -r ${CONN_STRING} << ***EoF***
    get ${DEPLOY_SSH_PATH}/work/deploy.log
***EoF***
    
    #
    # Eliminar directorio trabajo remoto
    #
    t_echo "----------------------------------------------------------------------------------------"
    t_echo "INFO Eliminando directorio de trabajo remoto.."
    t_echo "----------------------------------------------------------------------------------------"
    COMANDO="rm -Rf ${DEPLOY_SSH_PATH}/work"
    ssh -o StrictHostKeyChecking=no -i ${DEPLOY_SSH_KEY} ${CONN_STRING} "${COMANDO}" || \
     	echo "WARN No se ha podido eliminar el directorio de trabajo remoto"
    t_echo "DEBUG Directorio de tabajo eliminado"
    t_echo "INFO Log del script de despliegue remoto:"
    cat deploy.log
    t_echo "=============================================================================================="
    t_echo "INFO Etapa deploy finalizada con codigo de retorno $ret"
    t_echo "=============================================================================================="
    exit $ret
}
