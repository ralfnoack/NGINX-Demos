#!/bin/bash

# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/#docker_plus

BANNER="NGINX Opensource/Plus & NGINX Agent Docker image builder\n\n
This tool builds a Docker image to run NGINX Opensource/Plus and NGINX Agent\n\n
=== Usage:\n\n
$0 [options]\n\n
=== Options:\n\n
-h\t\t\t- This help\n
-t [target image]\t- The Docker image to be created\n
-C [file.crt]\t\t- Certificate to pull packages from the official NGINX repository\n
-K [file.key]\t\t- Key to pull packages from the official NGINX repository\n
-n [URL]\t\t- NGINX Instance Manager / NGINX SaaS console URL to fetch the agent\n
-w\t\t\t- Add NGINX App Protect WAF (requires NGINX Plus)\n
-O\t\t\t- Use NGINX Opensource instead of NGINX Plus\n\n
=== Examples:\n\n
NGINX Plus and NGINX Agent image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:latest -n https://nim.f5.ff.lan\n\n
NGINX Plus, NGINX App Protect WAF and NGINX Agent image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:latest-nap -w -n https://nim.f5.ff.lan\n\n
NGINX Opensource and NGINX Agent image:\n
  $0 -O -t registry.ff.lan:31005/nginx-oss-with-agent:latest -n https://nim.f5.ff.lan\n"

while getopts 'ht:C:K:a:n:wO' OPTION
do
	case "$OPTION" in
		h)
			echo -e $BANNER
			exit
		;;
		t)
			IMAGENAME=$OPTARG
		;;
		C)
			NGINX_CERT=$OPTARG
		;;
		K)
			NGINX_KEY=$OPTARG
		;;
		n)
			NMSURL=$OPTARG
		;;
		w)
			NAP_WAF=true
		;;
		O)
			NGINX_OSS=true
		;;
	esac
done

if [ -z "$1" ]
then
	echo -e $BANNER
	exit
fi

if [ -z "${IMAGENAME}" ]
then
        echo "Docker image name is required"
        exit
fi

if [ -z "${NMSURL}" ]
then
        echo "NGINX Instance Manager / NGINX SaaS console URL is required"
        exit
fi

if ([ -z "${NGINX_OSS}" ] && ([ -z "${NGINX_CERT}" ] || [ -z "${NGINX_KEY}" ]) )
then
        echo "NGINX certificate and key are required for automated installation"
        exit
fi

echo "=> Target docker image is $IMAGENAME"

if ([ ! -z "${NAP_WAF}" ] && [ -z "${NGINX_OSS}" ])
then
echo "=> Building with NGINX App Protect WAF support"
fi

if [ -z "${NGINX_OSS}" ]
then
	DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.plus \
		--secret id=nginx-key,src=$NGINX_KEY --secret id=nginx-crt,src=$NGINX_CERT \
		--build-arg NMS_URL=$NMSURL --build-arg NAP_WAF=$NAP_WAF -t $IMAGENAME .
else
	DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.oss \
		--build-arg NMS_URL=$NMSURL -t $IMAGENAME .
fi

echo "=> Build complete for $IMAGENAME"
docker push $IMAGENAME
