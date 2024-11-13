#Dockerfile vars

#vars
IMAGENAME=docker-matrix
IMAGEFULLNAME=avhost/${IMAGENAME}
TAG=$(shell git describe --tags --abbrev=0)
BRANCH=$(shell git symbolic-ref --short HEAD | xargs basename)
BRANCHSHORT=$(shell echo ${BRANCH} | awk -F. '{ print $$1"."$$2 }')
LASTCOMMIT=$(shell git log -1 --pretty=short | tail -n 1 | tr -d " " | tr -d "UPDATE:")
TAG_SYN=v1.119.0
BV_SYN=release-v1.119
BUILDDATE=$(shell date -u +%Y%m%d)


.DEFAULT_GOAL := all

ifeq (${BRANCH}, master)
    BRANCH=latest
    BRANCHSHORT=latest
endif

build:
	@echo ">>>> Build docker image latest"
	BUILDKIT_PROGRESS=plain docker buildx build --no-cache --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} -t ${IMAGEFULLNAME}:latest .

push:
	@echo ">>>> Publish docker image: " ${BRANCH}
	@docker buildx create --use --name buildkit
	@docker buildx build --sbom=true --provenance=true --platform linux/amd64 --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} --push -t ${IMAGEFULLNAME}:${BRANCH} .
	@docker buildx build --sbom=true --provenance=true --platform linux/amd64 --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} --push -t ${IMAGEFULLNAME}:${BRANCHSHORT} .
	@docker buildx build --sbom=true --provenance=true --platform linux/amd64 --build-arg TAG_SYN=${TAG_SYN} --build-arg BV_SYN=${BV_SYN} --push -t ${IMAGEFULLNAME}:latest .
	@docker buildx rm buildkit


all: build 
