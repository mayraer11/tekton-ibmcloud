# Desplegando Aplicaciones con IBM DevOps

#### **Introducción**
Este tutorial muestra como configurar un pipeline elaborado con tekton haciendo uso de IBM Continuos Delivery y IBM Toolchain. con la finalidad de construir y desplegar una aplicación nodejs en cloud foundry, asimismo comprendera los conceptos necesarios para crear sus propios pipelines con tekton.

#### **Requisitos Previos**
- Contar con una cuenta en [IBMCloud](https://cloud.ibm.com/)
- Contar con una cuenta en [GitHub](http://github.com/)
- Contar con una cuenta de [Slack](https://slack.com/) y tener un canal creado.

> [!TIP]
> Al iniciar este tutorial debe estar logueado en las 3 cuentas mencionadas con anterioridad para facilitar la implementación.

> [!IMPORTANT]
> Todos los componentes deben ser creados en la misma region y el mismo resource group para evitar posibles conflictos.
> 
#### **Tiempo Estimado**
El tiempo estimado para completar el tutorial es de 60 a 90 minutos.

#### **Pasos**

1. Obtener información de herramientas a integrar.
    - Para poder integrar tekton con ibm toolchain sus plantillas yml deben estar versionadas en un repositorio por lo cual puede crear uno de la siguiente manera:
        - Ingrese [aqui](https://github.com/new)
        - Seleccionar un propietario.
        - Ingresar un nombre para el repositorio.
        - Seleccionar si desea que sea publico o privado.
        - dar click en *Create repository*
        <img src="images/createrepo.gif" width="400" height="350" style="vertical-align:middle;margin:0px 50px">

    - Para poder integrar slack a ibm toolchain vamos a requerir crear una aplicación dentro de slack de la siguiente forma:
        - Ingrese [aqui](https://api.slack.com/apps)
        - De click en el boton Create New App
        - Ingrese un nombre para su app
        - De click en el boton Create App
    - Una vez creada la aplicacion del paso anterior procederemos a crear un webhook de la siguiente forma:
        - Ingresamos a la seccion de *información basica* de la aplicación creada anteriormente.
        - Seleccionamos Incoming WebHooks.
        - Una vez dentro cambiamos la opción a *On*.
        - en la parte inferior damos click en el boton Add New Webhook to Workspace.
        - Seleccionamos el canal de nuestra preferencia.
        - Copiamos el Webhook URL en un lugar seguro.
1. Creación de Key Protect

    - Ingrese [aqui](https://cloud.ibm.com/catalog/services/key-protect)
    - Ingrese un nombre para el repositorio de claves
    - Seleccionar un grupo de recursos.
    - Dar click en crear.

1. Creación de IBM ToolChain.

    - Ingrese [aqui](https://cloud.ibm.com/devops/create)
    - Seleccione la opción *Cree su propia cadena de herramientas*
    - Ingrese un nombre
    - Seleccione una region
    - Seleccione un grupo de recursos
    - De click en crear

1. Añadiendo herramientas a IBM ToolChain
    - Github
        - Dar click en *añadir herramienta*
        - Buscar *github* y seleccionar.
        - Dar click en el boton autorizar y Aceptar.
        - En el Tipo de Repositorio seleccionar *Existente*.
        - Seleccionar la URL de nuestro repositorio (creado en el paso 1).
        - Marcar ambos checks para habilitar el seguimiento.
        - Dar click en el boton *Crear Integración*.
    - Slack
        - Dar click en *añadir herramienta*
        - Buscar *Slack* y seleccionar.
        - Ingrese la URL de WebHook (obtenido en el paso 1)
        - Ingrese el nombre de su canal de slack.
        - Ingrese el nombre de su equipo de slack.
        - Dar click en el boton *Crear Integración*.
    - KeyProtect
        - Dar click en *añadir herramienta*
        - Buscar KeyProtect y seleccionar.
        - Seleccione la región donde creo su keyprotect.
        - Seleccione el grupo de recursos donde se encuentra su keyprotect.
        - Ingrese el nombre asignado a su keyprotect.
        - Dar click en el boton Crear Integración.
    - DevOps Insights
        - Dar click en *añadir herramienta*
        - Buscar DevOps Insights y seleccionar.
        - Dar click en el boton Crear Integración.
    - IBM Delivery Pipeline
        - Dar click en *añadir herramienta*
        - Buscar Delivery Pipeline y seleccionar.
        - Ingrese un nombre.
        - Seleccione Tekton como Tipo de conducto.
        - Dar click en el boton Crear Integración.


Tekton en IBM Delivery Pipeline

Como podemos visualizar en el siguiente imagen tekton nos permitira crear recursos dentro del cluster publico gestionado por IBM para poder ejecutar los pasos indicados en el pipeline.

![Flow Tekton](images/tekton.png?raw=true "Flow Tekton")

Los siguientes bloques de codigo deberan ser copiados dentro de un archivo yml y versionados dentro de una carpeta tekton en el repositorio creado anteriormente.

1. Configurando IBM Delivery Pipeline.

    - Creación de EventListener: Permite procesar eventos entrantes de forma declarativa.

        ```yml
        apiVersion: tekton.dev/v1beta1
        kind: EventListener
        metadata:
          name: eventlistener
        spec:
          triggers:
            - binding:
                name: triggerbinding
              template:
                name: triggertemplate
        ```

    - Creación de Trigger binding: Permite la capturar campos de un evento y almacenarlos como parametros.
        
        ```yml
        ApiVersion: tekton.dev/v1beta1
        kind: TriggerBinding
        metadata:
          name: triggerbinding
        spec:
          params:
            - name: repository
              value: URL
        ```

    - Creacion de Trigger Template: Es un modelo base que puede ser reutilizable.

        
        ```yml
        apiVersion: tekton.dev/v1beta1
        kind: TriggerTemplate
        metadata:
          name: triggertemplate
        spec:
          params:
            - name: repository
              description: Repositorio GIT
          resourcetemplates:
            - apiVersion: v1
              kind: PersistentVolumeClaim
              metadata:
                name: pipelinerun-$(uid)-pvc2
              spec:
                resources:
                  requests:
                    storage:  5Gi
                volumeMode: Filesystem
                accessModes:
                  - ReadWriteOnce
        #PIPELINE RUN
            - apiVersion: tekton.dev/v1beta1
              kind: PipelineRun
              metadata:
                name: pipelinerun-$(uid)
              spec:
                pipelineRef:
                    name: pipeline
                workspaces:
                  - name: pipeline-pvc
                    persistentVolumeClaim:
                      claimName: pipelinerun-$(uid)-pvc2
                params:
                - name: repository
                  value: $(params.repository)
        ```

    - Creación de Task de clonación de repositorio

        ```yml
        apiVersion: tekton.dev/v1beta1
                kind: Task
                metadata:
                  name: clone-task
                spec:
                  params:
                    - name: repository
                      description: Repositorio GIT
                  workspaces:
                  - name: task-pvc
                    mountPath: /workspace   
                  steps:
                    - name: clone-repo
                      image: alpine/git:v2.26.2
                      workingDir: workspace
                      env:
                        - name: REPOSITORY
                          value: $(params.repository)
                        - name: BRANCH
                          valueFrom:
                              configMapKeyRef:
                                name: environment-properties
                                key: branch
                      command: ["/bin/sh", "-c"]
                      args:
                        - set -e -o pipefail;
                          echo "Cloning $REPOSITORY";
                          rm -rf app;          
                          git clone -q -b $BRANCH $REPOSITORY;
        ```

    - Creación de Task de Contrucción (Build)

        ```yml
        ---
                apiVersion: tekton.dev/v1beta1
                kind: Task
                metadata:
                  name: build-task
                spec:
                  params:
                    - name: repository
                      description: Repositorio GIT
                  workspaces:
                  - name: task-pvc
                    mountPath: /artifacts   
                  steps:          
                    - name: build
                      image: ibmcom/pipeline-base-image:2.11
                      workingDir: /
                      env:
                        - name: HOME
                          value: "/root"
                      command: ["/bin/bash", "-c"]
                      args:
                        - cd /workspace;
                          cd app/client;
                          npm install;
                          npm run build;
                    - name: publish-artifact
                      image: ibmcom/pipeline-base-image:2.11
                      workingDir: /
                      env:
                        - name: HOME
                          value: "/root"
                      command: ["/bin/bash", "-c"]
                      args:
                        - cp -r workspace artifacts;
        ```
    

    - Creación de Task de Despliegue (Deploy)

        ```yml
        ---
        apiVersion: tekton.dev/v1beta1
        kind: Task
        metadata:
          name: deploy-task
        spec:
          workspaces:
          - name: task-pvc
            mountPath: /artifacts
          steps:
            - name: deploy-cf-app
              image: ibmcom/pipeline-base-image:2.11
              workingDir: /artifacts/workspace/app
              env:
                - name: CF_APP
                  valueFrom:
                      configMapKeyRef:
                        name: environment-properties
                        key: cf-app
                - name: CF_ORG
                  valueFrom:
                      configMapKeyRef:
                        name: environment-properties
                        key: cf-org
                - name: CF_SPACE
                  valueFrom:
                      configMapKeyRef:
                        name: environment-properties
                        key: cf-space
                - name: CF_REGION
                  valueFrom:
                      configMapKeyRef:
                        name: environment-properties
                        key: cf-region
                - name: IBM_CLOUD_API
                  valueFrom:
                      configMapKeyRef:
                        name: environment-properties
                        key: ibm-cloud-api
                - name: CF_API
                  valueFrom:
                      configMapKeyRef:
                        name: environment-properties
                        key: cf-api
                - name: PIPELINE_BLUEMIX_API_KEY
                  valueFrom:
                    secretKeyRef:
                      name: secure-properties
                      key: bluemix-api-key
                - name: HOME
                  value: "/root"
              script: |
                #!/bin/bash
                ls
                export CF_EXEC="ibmcloud cf"
                ibmcloud config --check-version false
                ibmcloud login -a $IBM_CLOUD_API -r $CF_REGION --apikey $PIPELINE_BLUEMIX_API_KEY
                ibmcloud target --cf-api $CF_API -o "$CF_ORG" -s "$CF_SPACE"
        
                if ! cf app "$CF_APP"; then  
                  cf push "$CF_APP"
                else
                  OLD_CF_APP="${CF_APP}-OLD-$(date +"%s")"
                  rollback() {
                    set +e  
                    if cf app "$OLD_CF_APP"; then
                      cf logs "$CF_APP" --recent
                      cf delete "$CF_APP" -f
                      cf rename "$OLD_CF_APP" "$CF_APP"
                    fi
                    exit 1
                  }
                  set -e
                  trap rollback ERR
                  cf rename "$CF_APP" "$OLD_CF_APP"
                  cf push "$CF_APP"
                  cf delete "$OLD_CF_APP" -f
                fi
                export CF_APP_NAME="$CF_APP"
                export APP_URL=http://$(cf app $CF_APP_NAME | grep -e urls: -e routes: | awk '{print $2}')
        ```


    - Creación de Pipeline

        ```yml
        apiVersion: tekton.dev/v1beta1
        kind: Pipeline
        metadata:
          name: pipeline
        spec:
          params:
            - name: repository
              description: Repositorio GIT
          workspaces:
          - name: pipeline-pvc
          tasks:
            - name: pipeline-clone-task
              taskRef:
                name: clone-task
              params:
                - name: repository
                  value: $(params.repository)
              workspaces:
              - name: task-pvc
                workspace: pipeline-pvc
            - name: pipeline-build-task
              runAfter: [pipeline-clone-task]
              taskRef:
                name: build-task
              params:
                - name: repository
                  value: $(params.repository)
              workspaces:
              - name: task-pvc
                workspace: pipeline-pvc
            - name: pipeline-deploy-task
              runAfter: [pipeline-build-task]
              taskRef:
                name: deploy-task
              workspaces:
              - name: task-pvc
                workspace: pipeline-pvc
        ```

#### **Resumen**
Este tutorial le ha ayudado a comprender y configurar su primer pipeline con IBM DevOps Ecosystem, comprendiendo los compenentes necesarios para trabajar con tekton, permitiendo asi agilizar sus despliegues.