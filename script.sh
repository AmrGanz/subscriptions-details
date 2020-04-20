offline_token=''

contractid=


function jsonValue() {
KEY=$1
num=$2
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

token=`curl -s https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token | jsonValue access_token`

curl -s -H "Authorization: Bearer $token" -X GET "https://api.access.redhat.com/management/v1/subscriptions" -H "accept: application/json" | jq -r --arg contractid "$contractid" '.body[] | select( .contractNumber == $contractid)' | jq -r .subscriptionNumber > /tmp/subid

for subid in `cat /tmp/subid`
do
	echo "===================================================="
	echo "subscription ID: $subid"
	subname=`curl -s -H "Authorization: Bearer $token" -X GET "https://api.access.redhat.com/management/v1/subscriptions" -H "accept: application/json" | jq -r --arg subid "$subid" '.body[] | select( .subscriptionNumber == $subid)' | jq -r .subscriptionName`
	echo "Subscription Name: $subname"
	systems=`curl -s -H "Authorization: Bearer $token" -X GET "https://api.access.redhat.com/management/v1/subscriptions/$subid/systems" -H "accept: application/json"  | jq -r '.body[].systemName'`
	echo "Systems:"
	for x in $systems
	do
		echo $x
	done
	echo "===================================================="
done


