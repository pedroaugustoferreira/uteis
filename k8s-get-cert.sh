#!/bin/bash
#set -x



getDate()
{
NAMESPACE="$1"
SECRET_NAME="$2"
CERT_FIELD="$3"

kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" -o jsonpath='{.data}' | jq -r ".[\"$CERT_FIELD\"]" | base64 -d | openssl x509 -noout -enddate | cut -d'=' -f2
}


getSubject()
{
NAMESPACE="$1"
SECRET_NAME="$2"
CERT_FIELD="$3"

kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" -o jsonpath='{.data}' | jq -r ".[\"$CERT_FIELD\"]" | base64 -d | openssl x509 -noout -subject
}

getIssuer()
{
NAMESPACE="$1"
SECRET_NAME="$2"
CERT_FIELD="$3"

kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" -o jsonpath='{.data}' | jq -r ".[\"$CERT_FIELD\"]" | base64 -d | openssl x509 -noout -issuer
}

getDNS()
{

NAMESPACE="$1"
SECRET_NAME="$2"
CERT_FIELD="$3"

kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" -o jsonpath='{.data}' | jq -r ".[\"$CERT_FIELD\"]" | base64 -d | openssl x509 -noout -text|egrep "DNS|Address"|sed 's|,|\n|g' | awk '{ gsub(/[ ]+/," "); print }'|sed 's|^ ||g'
echo "|"
}



for info in $(kubectl get secret -A|grep kubernetes.io/tls|awk '{print $1";"$2}')
do
    #echo $info
    ns=$(echo $info|cut -d";" -f1)
    secret=$(echo $info|cut -d";" -f2)
    for files in $(kubectl -n $ns describe secret/$secret |grep -A 1000 "==" | egrep -v "key|=" | awk '{print $1}'|tr -d ":")
    do
	    printf "$ns;$secret;$files;$(getDate $ns $secret $files);$(getSubject $ns $secret $files);$(getIssuer $ns $secret $files)"
	    echo " "
	    getDNS $ns $secret $files
        # kubectl -n cattle-system get secret tls-rancher -o jsonpath='{.data}' |jq -r '.["tls.crt"]'|base64 -d
	#getDate $ns $secret $files
	#getSubject $ns $secret $files
	#./get-sub.sh $ns $secret $files
    done 
done|column -t -s";" 


