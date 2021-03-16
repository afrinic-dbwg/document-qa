WORKSPACE=/opt/working
PWD=$$(pwd)
SHELL=/bin/bash -O globstar

.PHONY: test
test: Dockerfile entrypoint.sh dictionary markdownlint.yml
	docker run --rm \
	           --tty \
	           --volume "$(PWD):$(WORKSPACE)" \
	           "$$(docker build -q $(PWD))"

.PHONY: spell
spell:
	docker run --rm \
	           --tty \
			   --interactive \
	           --volume "$(PWD):$(WORKSPACE)" \
	           "$$(docker build -q $(PWD))" \
			   --interactive
