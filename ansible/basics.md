# Ansible

### Ad-Hoc Command

Ad-Hoc commands are a way to directly interacting with ansible without having to write playbooks

#### The ansible command

There are several arguments passed to the `ansible` command.

- `-u` statnds for the user as whom the payload should be executed.
- `-m` stands for the module which has to be send as the payload.
- `-a` is for specifying the arguments to the module.

### Modules

#### _User Module_

User module can be used for managing users and user-attributes on target systems. It has several arguments

- `name` = name of the user
- `state` = The declarative status of the specified user. It could be `absent`, `precent` etc..

### Tags

While running a playbook, tags can be used to select or skip tasks to run.

`$ ansible-playbook -i inventoryfile.ini -u root --tags=[tag-1, tag-2]` Will only execute tasks that has `tag-1` and `tag-2`.

`$ ansible-playbook -i inventoryfile.ini -u root --skip-tags=[tag-1, tag-2]` Will only execute tasks that doesn't have `tag-1` and `tag-2`.
