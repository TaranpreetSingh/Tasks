#!/bin/sh
 DAYS="604800" 
 YOUR_WEBHOOK_URL=""
 echo "Input the cluster name"
 read -r cluster
 echo "Input the namespace"
 read -r namespace
 for i in `kubectl --context $cluster get cm -n $namespace | awk '{print $1}' | grep -vi name`
 do
     filename="cm_$i'_'$namespace.pem"
     if `kubectl --context $cluster  -n $namespace get cm $i -o yaml | grep pem `
     then
         kubectl --context $cluster  -n $namespace get cm $i -o yaml | yq .data  | grep pem | awk -F":" '{print $2}'  > $filename
         cert_expr_date=$(openssl x509 -enddate -noout -in $filename | awk -F"=" '{print $2}')
         openssl x509 -enddate -noout -in $filename  -checkend "$DAYS" | grep -q 'Certificate will expire'
         if [ $? -eq 0 ]
         then
             curl -X POST -H 'Content-type: application/json' --data '{"text":"Certificate in configmap with name '$i' in namespace '$namespace' will expire in 7 days "}' $YOUR_WEBHOOK_URL
             curl -X POST -H 'Content-type: application/json' --data '{"text":"Certificate in configmap with name '$i' in namespace '$namespace' will expire on '$cert_expr_date' "}' $YOUR_WEBHOOK_URL
         fi
     fi
 done
 for i in `kubectl --context $cluster get secret -n $namespace | awk '{print $1}' | grep -vi name`
 do
      filename="secret_$i'_'$namespace.pem"
     if `kubectl --context $cluster  -n $namespace get secret $i -o yaml | grep pem `
     then
         kubectl --context $cluster  -n $namespace get secret $i -o yaml |yq .data | grep pem | awk -F":" '{print $2}' | base64 -d > $filename
         cert_expr_date=$(openssl x509 -enddate -noout -in $filename | awk -F"=" '{print $2}')
         openssl x509 -enddate -noout -in $filename  -checkend "$DAYS" | grep -q 'Certificate will expire'
         if [ $? -eq 0 ]
         then
             curl -X POST -H 'Content-type: application/json' --data '{"text":"Certificate in secret with name '$i' in namespace '$namespace' will expire in 7 days "}' $YOUR_WEBHOOK_URL
             curl -X POST -H 'Content-type: application/json' --data '{"text":"Certificate in configmap with name '$i' in namespace '$namespace' will expire on '$cert_expr_date' "}' $YOUR_WEBHOOK_URL
         fi
     fi
 done