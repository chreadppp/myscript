#!/bin/sh


verify_deployment() {
    for i in $(seq 9)
    do
        echo "[INFO] waiting all ai pod running..." &&sleep 60
        pod_running=$(kubectl  get pod -A |egrep -v Running|wc -l)
        if [ $pod_running -eq 1 ];then
            echo "[INFO] all ai pod running!" && break
        elif [ $i -eq 9 ];then
            echo "[FATAL] waiting for ai pod running timeout! exit" && exit 1
        fi
    done   
}


install_ai_center(){
    #load ai project images
    echo "[INFO] prepare ai integration images..."
    docker load -i images/ai-integration.tar
    echo "[INFO] deploy ai integration pod..."
    # label model delpoy node 
    kubectl label node gpu_server=true --all
    # prepare minio bucket.
    mkdir /data/minio/result -p && mkdir /data/minio/temp -p
    # prepare ns and image pull secret.
    kubectl  create ns idp && kubectl -n idp create secret docker-registry huawei-registry --docker-server=hub-dev.rockontrol.com --docker-username=pull-only --docker-password=h0nyhkLmNdZ9FWPc
    kubectl  create ns aisys-integration && kubectl -n aisys-integration create secret docker-registry huawei-registry --docker-server=hub-dev.rockontrol.com --docker-username=pull-only --docker-password=h0nyhkLmNdZ9FWPc
    # install idp
    kubectl  apply -f manifests/idp  -n idp
    # install ai-center
    kubectl  apply -f manifests/ai-center -n aisys-integration
}


install_modle_service(){
    [ -z "`egrep -v "#" model.list`" ] && echo "[WARN] no modle selected! \033[31m[warn]\033[0m"
    for i in `egrep -v "#" model.list`
    do
        case $i in
            "PERSON_INVASION")
            kubectl apply -f manifests/modles/srv-ai-detection-person-so.yaml -n aisys-integration
                ;;
            "LICENSE_PLATE")
                kubectl apply -f manifests/modles/srv-ai-detection-plate-amd64.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-plate-affine-ocr-amd64.yaml -n aisys-integration
                ;;
            "FACE_MASK")
                kubectl apply -f manifests/modles/srv-ai-detection-head-so.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-classification-face-mask-amd64.yaml -n aisys-integration
                ;;
            "NOT_VEHICLE_MISPLACE")
                kubectl apply -f manifests/modles/srv-ai-detection-universal-vehicle-amd64.yaml -n aisys-integration
                ;;
            "VEHICLE_MISPLACE")
                kubectl apply -f manifests/modles/srv-ai-detection-universal-vehicle-amd64.yaml -n aisys-integration
                ;;
            "SMOKE")
                kubectl apply -f manifests/modles/srv-ai-detection-smogfire-amd64.yaml -n aisys-integration
                ;;
            "LEAVE")
                kubectl apply -f manifests/modles/srv-ai-detection-person-so.yaml -n aisys-integration
                ;;
            "PERSON_DENSE_CROWD")
                kubectl apply -f manifests/modles/srv-ai-detection-head-so.yaml -n aisys-integration
                ;;
            "HELMET")
                kubectl apply -f manifests/modles/srv-ai-classification-personsmoke-amd64.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-classification-helmet-amd64.yaml -n aisys-integration
                ;;
            "PHONE")
                kubectl apply -f manifests/modles/srv-ai-detection-head-so.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-classification-phonecall-amd64.yaml -n aisys-integration
                ;;
            "SMOKING")
                kubectl apply -f manifests/modles/srv-ai-detection-head-so.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-classification-personsmoke-amd64.yaml -n aisys-integration
                ;;
            "PERSONFALL")
                kubectl apply -f manifests/modles/srv-ai-detection-person-so.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-classification-personfall-amd64.yaml -n aisys-integration
                ;;
            "CLIMB")
                kubectl apply -f manifests/modles/srv-ai-classification-person-climb-amd64.yaml -n aisys-integration
                ;;
            "BARELAND")
                kubectl apply -f manifests/modles/srv-ai-segmentation-bareland-amd64.yaml -n aisys-integration
                ;;
            "DUST")
                kubectl apply -f manifests/modles/srv-ai-detection-dust-amd64.yaml -n aisys-integration
                ;;
            "SLAG_CAR")
                kubectl apply -f manifests/modles/srv-ai-detection-construction-truck-amd64.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-classification-truck-covered-amd64.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-classification-truck-carried-amd64.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-detection-plate-amd64.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-plate-affine-ocr-amd64.yaml -n aisys-integration
                ;;
            "CAR_SMOKE")
                kubectl apply -f manifests/modles/srv-ai-detection-blacksmogvehicle-amd64.yaml -n aisys-integration
                ;;
            "GARBAGE_EXPOSURE")
                kubectl apply -f manifests/modles/srv-ai-segmentation-garbage-amd64.yaml -n aisys-integration
                ;;
            "RIVER_GARBAGE")
		kubectl apply -f manifests/modles/srv-ai-segmentation-river-garbage-amd64.yaml -n aisys-integration
		;;
            "CAR_WASH")
                kubectl apply -f manifests/modles/srv-ai-detection-universal-vehicle-amd64.yaml -n aisys-integration
            kubectl apply -f manifests/modles/srv-ai-segmentation-waterspray-amd64.yaml -n aisys-integration
            kubectl apply -f manifests/modles/srv-ai-detection-plate-amd64.yaml -n aisys-integration
            kubectl apply -f manifests/modles/srv-ai-plate-affine-ocr-amd64.yaml -n aisys-integration
                ;;
            "SLEEP")
                kubectl apply -f manifests/modles/srv-ai-classification-personsleep-amd64.yaml -n aisys-integration
                kubectl apply -f manifests/modles/srv-ai-detection-person-so.yaml -n aisys-integration
                ;;
        *)
            echo -e "[WARN] no modle find! \033[31m[warn]\033[0m"

                ;;
        esac
    done   
}





install_ai_center
install_modle_service
verify_deployment



