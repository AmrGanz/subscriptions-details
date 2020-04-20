offline_token=''

contractid=


function jsonValue() {
KEY=$1
num=$2
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

token=`curl -s https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token | jsonValue access_token`

# Creating a temporary directory to hold API calls outputs:
mkdir -p /tmp/temp-dir/subids

# Requesting all subscriptions attached to one Contacrt ID:
curl -s -H "Authorization: Bearer $token" -X GET "https://api.access.redhat.com/management/v1/subscriptions" -H "accept: application/json" | jq -r > /tmp/temp-dir/subs

# Filtering out all Subscriptions ID
cat /tmp/temp-dir/subs | jq -r --arg contractid "$contractid" '.body[] | select( .contractNumber == $contractid)' | jq -r .subscriptionNumber > /tmp/temp-dir/subid

# Requesting Systems information attached to one Subscription ID:
for subid in `cat /tmp/temp-dir/subid`
do
	curl -s -H "Authorization: Bearer $token" -X GET "https://api.access.redhat.com/management/v1/subscriptions/$subid/systems" -H "accept: application/json"  | jq -r  > /tmp/temp-dir/subids/$subid
done

# Filtering out all Systems names:
cat /tmp/temp-dir/subids/* | jq -r .body[].systemName | sort | uniq > /tmp/temp-dir/systems

for system in `cat /tmp/temp-dir/systems`
do
	echo "===================================================="
	echo "System Name: $system"
	echo "Type: `cat /tmp/temp-dir/subids/* | jq -r --arg system "$system" '.body[] | select( .systemName == $system)'  | jq -r .type | head -n1`"
	for x in `ls /tmp/temp-dir/subids/`
	do
		value=`cat /tmp/temp-dir/subids/$x | jq -r --arg system "$system" '.body[] | select( .systemName == $system)' | jq -r .systemName`
		if [ -z "$value" ]
		then
			:
		else
			echo "-------------------"
			echo "Subscription name: `cat /tmp/temp-dir/subs | jq -r --arg x "$x" '.body[] | select( .subscriptionNumber == $x)' | jq -r .subscriptionName`"
			echo "Subscription ID: `cat /tmp/temp-dir/subs | jq -r --arg x "$x" '.body[] | select( .subscriptionNumber == $x)' | jq -r .subscriptionNumber`"
			echo "Total Entitlement Quantity: `cat /tmp/temp-dir/subids/$x | jq -r --arg system "$system" '.body[] | select( .systemName == $system)'  | jq -r .totalEntitlementQuantity`"
			echo "-------------------"
		fi
	done
done

