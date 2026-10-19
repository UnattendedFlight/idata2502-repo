.PHONY: default ansible plan apply tf all help

default: help

ansible:
	ansible-playbook -i ansible/local/inventory.ini ansible/local/site.yml

plan:
	terraform -chdir=terraform/local plan

apply:
	terraform -chdir=terraform/local apply

tf: plan apply

all: apply ansible

help:
	@echo "Usage: make tf|plan|apply|ansible|all|help"