#!/bin/bash

docker compose build

run(){
	echo "UPLOAD=$1" > example/network.env
	echo "RTT=$2" >> example/network.env
	echo "LOSS=$3" >> example/network.env

	docker compose run --remove-orphans client
}

for BW in 40000 100 50 20 10 5 2 1; do
	run "$BW" 0 0
done

for LOSS in 1 2 5; do
	run 100 0 "$LOSS"
done

for RTT in 10 20 50 100 200 500; do
	run 100 "$RTT" 0
done

for TECHNOLOGY in 3g 4g; do

	for QUALITY in bad medium good; do

		echo "TECHNOLOGY=$TECHNOLOGY" > example/network.env
		echo "QUALITY=$QUALITY" >> example/network.env

		docker compose run --remove-orphans client
	done
done

echo "OPERATOR=starlink" > example/network.env
echo "TECHNOLOGY=leosat" >> example/network.env
docker compose run --remove-orphans client

echo "TECHNOLOGY=geosat" > example/network.env
docker compose run --remove-orphans client
