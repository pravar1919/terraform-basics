# Terraform Commands
    - terraform init
    (.terraform/plugins/linux_amd64/)
    - terraform plan 
    (after creating the .tf file)
    - terraform apply
    for executing the .tf content
    - terraform destroy
    delete the resources of the .tf file.

    - terraform plan -out plan.out # to store the state of the plan in a file, can be use by apply command.
    - terraform apply plan.out # not ask for confirmation.

# Provisioners
    - helps to run script on the machine

# connections
    - to connect the host machine

