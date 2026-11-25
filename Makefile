.PHONY: default ansible plan apply tf all help cloud-plan cloud-apply cloud-destroy

default: help

ansible:
	ansible-playbook -i ansible/inventory.ini ansible/site.yml

plan:
	terraform -chdir=terraform/local plan

apply:
	terraform -chdir=terraform/local apply

tf: plan apply

cloud-plan:
	terraform -chdir=terraform/cloud plan

cloud-apply:
	terraform -chdir=terraform/cloud apply

cloud-destroy:
	terraform -chdir=terraform/cloud destroy

all: apply ansible

help:
	@echo "Usage: make tf|plan|apply|inventory|cloud-plan|cloud-apply|cloud-destroy|ansible|all|help"