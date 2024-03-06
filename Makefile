network:
	docker network create mongolab-network

rs:
	docker run -d --rm -p 27017:27017 --name mongolab-db1 --network mongolab-network mongo mongod --replSet rs0 --bind_ip localhost,mongolab-db1
	docker run -d --rm -p 27018:27017 --name mongolab-db2 --network mongolab-network mongo mongod --replSet rs0 --bind_ip localhost,mongolab-db2
	docker run -d --rm -p 27019:27017 --name mongolab-db3 --network mongolab-network mongo mongod --replSet rs0 --bind_ip localhost,mongolab-db3
	docker exec -it mongolab-db1 mongosh --eval "rs.initiate({ \
		_id: \"rs0\", \
		members: [ \
			{ _id: 0, host: \"mongolab-db1:27017\", priority: 2 }, \
			{ _id: 1, host: \"mongolab-db2:27017\", priority: 0 }, \
			{ _id: 2, host: \"mongolab-db3:27017\", priority: 0 } \
		] \
	})"
	docker exec -it mongolab-db1 mongosh --eval "rs.status()"

rs-status:
	docker exec -it mongolab-db1 mongosh --eval "rs.status()"

cs:
	docker run -d --rm -p 27020:27017 --name mongolab-configsvr1 --network mongolab-network mongo mongod --configsvr --replSet configsvr-rs --dbpath /data/db --port 27017 --bind_ip localhost,mongolab-configsvr1
	docker run -d --rm -p 27021:27017 --name mongolab-configsvr2 --network mongolab-network mongo mongod --configsvr --replSet configsvr-rs --dbpath /data/db --port 27017 --bind_ip localhost,mongolab-configsvr2
	docker run -d --rm -p 27022:27017 --name mongolab-configsvr3 --network mongolab-network mongo mongod --configsvr --replSet configsvr-rs --dbpath /data/db --port 27017 --bind_ip localhost,mongolab-configsvr3
	docker exec -it mongolab-configsvr1 mongosh --eval "rs.initiate({ \
		_id: \"configsvr-rs\", \
		configsvr: true, \
		members: [ \
			{ _id: 0, host: \"mongolab-configsvr1:27017\" }, \
			{ _id: 1, host: \"mongolab-configsvr2:27017\" }, \
			{ _id: 2, host: \"mongolab-configsvr3:27017\" } \
		] \
	})"

cs-status:
	docker exec -it mongolab-configsvr1 mongosh --eval "rs.status()"

cs-stop:
	docker container stop mongolab-configsvr1 mongolab-configsvr2 mongolab-configsvr3
	docker container prune

shard:
	docker run -d --rm -p 27023:27017 --name mongolab-shardsvr1 --network mongolab-network mongo mongod --shardsvr --replSet shardsvr-rs --dbpath /data/db --port 27017 --bind_ip localhost,mongolab-shardsvr1
	docker run -d --rm -p 27024:27017 --name mongolab-shardsvr2 --network mongolab-network mongo mongod --shardsvr --replSet shardsvr-rs --dbpath /data/db --port 27017 --bind_ip localhost,mongolab-shardsvr2
	docker run -d --rm -p 27025:27017 --name mongolab-shardsvr3 --network mongolab-network mongo mongod --shardsvr --replSet shardsvr-rs --dbpath /data/db --port 27017 --bind_ip localhost,mongolab-shardsvr3
	docker exec -it mongolab-shardsvr1 mongosh --eval "rs.initiate({ \
		_id: \"shardsvr-rs\", \
		members: [ \
			{ _id: 0, host: \"mongolab-shardsvr1:27017\" }, \
			{ _id: 1, host: \"mongolab-shardsvr2:27017\" }, \
			{ _id: 2, host: \"mongolab-shardsvr3:27017\" } \
		] \
	})"

shard-status:
	docker exec -it mongolab-configsvr1 mongosh --eval "rs.status()"

mongos:
	docker run -d --rm -p 27026:27017 --name mongolab-mongos1 --network mongolab-network mongo mongos --configdb configsvr-rs/mongolab-configsvr1:27017,mongolab-configsvr2:27017,mongolab-configsvr3:27017 --port 27017 --bind_ip localhost,mongolab-mongos1

add-shard:
	docker exec -it mongolab-mongos1 mongosh --eval "sh.addShard( \
		\"shardsvr-rs/mongolab-shardsvr1:27017,mongolab-shardsvr2:27017,mongolab-shardsvr3:27017\" \
	)"

enable-sharding:
	docker exec -it mongolab-mongos1 mongosh --eval "sh.enableSharding(\"test\")"

shard-collection:
	docker exec -it mongolab-mongos1 mongosh --eval "sh.shardCollection( \
		\"<database>.<collection>\", { <shard key field> : \"hashed\" , ... } \
	)"