.PHONY: default help plan apply tf ansible ansible-local all \
	cloud-plan cloud-apply cloud-destroy inventory host-secret rebuild

default: help

# local lab server: offline test target for the playbook
plan:
	terraform -chdir=terraform/local plan

apply:
	terraform -chdir=terraform/local apply

tf: plan apply

ansible-local:
	ansible-playbook -i ansible/inventory.local.ini ansible/site.yml

# the VM
cloud-plan:
	terraform -chdir=terraform/cloud plan

cloud-apply:
	terraform -chdir=terraform/cloud apply

cloud-destroy:
	terraform -chdir=terraform/cloud destroy

inventory:
	sed "s/129\.241\.101\.X/$$(terraform -chdir=terraform/cloud output -raw public_ip)/" ansible/inventory.ini.example > ansible/inventory.ini

host-secret:
	gh secret set VM_HOST --body "$$(terraform -chdir=terraform/cloud output -raw public_ip)"

ansible:
	ansible-playbook -i ansible/inventory.ini ansible/site.yml

all: apply ansible-local

# tear down th VM and build it again from code
# destroy and apply still ask for "yes"
# then
# gh workflow run main.yml
# to deploy the app and the monitoring stack
rebuild:
	$(MAKE) cloud-destroy
	$(MAKE) cloud-apply
	$(MAKE) inventory
	$(MAKE) ansible
	$(MAKE) host-secret

help:
	@echo "Usage: make rebuild|cloud-plan|cloud-apply|cloud-destroy|inventory|host-secret|ansible"
	@echo "       make tf|plan|apply|ansible-local|all   (local lab server, offline)"
