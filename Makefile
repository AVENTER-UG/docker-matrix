#Dockerfile vars

#vars
IMAGENAME=docker-matrix
IMAGEFULLNAME=avhost/${IMAGENAME}
TAG=v1.139.2
BV_SYN=release-v1.139
BRANCH=${TAG}
BRANCHSHORT=$(shell echo ${BRANCH} | awk -F. '{ print $$1"."$$2 }')
LASTCOMMIT=$(shell git log -1 --pretty=short | tail -n 1 | tr -d " " | tr -d "UPDATE:")
TAG_SYN=${TAG}
BUILDDATE=$(shell date -u +%Y%m%d)


.DEFAULT_GOAL := all

build:
	@echo ">>>> Build docker image latest"
	BUILDKIT_PROGRESS=plain docker build --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} -t ${IMAGEFULLNAME}:latest .

push:
	@echo ">>>> Publish docker image: " ${BRANCH} ${BRANCHSHORT}
	@docker buildx create --use --name buildkit
	@docker buildx build --sbom=true --provenance=true --platform linux/amd64 --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} --push -t ${IMAGEFULLNAME}:${BRANCH} .
	@docker buildx build --sbom=true --provenance=true --platform linux/amd64 --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} --push -t ${IMAGEFULLNAME}:${BRANCHSHORT} .
	@docker buildx build --sbom=true --provenance=true --platform linux/amd64 --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} --push -t ${IMAGEFULLNAME}:latest .
	@docker buildx rm buildkit


all: build 
