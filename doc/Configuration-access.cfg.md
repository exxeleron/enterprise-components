User access and security settings (access.cfg)

### Security model description

### Adding new user query
  - see [Lesson04](../tutorial/Lesson04)
  - User queries are the main interfaces users can interact with. Those interfaces are defined using q language on `accessPoint` components.

### Generating user password
  - see [Lesson05](../tutorial/Lesson05)
  In order to generate a new encrypted password for a user, please run `admin.genPass` interactive
  service:
  ```
  $ yak console admin.genPass
  Please enter new password: USERINPUT
  Please re-enter new password: USERINPUT
  Your new password is: 0x6160e6574666
  ```  
  New password (`0x6160e6574666`) should be later placed in `access.cfg` file.

### Configuring user and/or groups
  - see [Lesson05](../tutorial/Lesson05)
  1. Setup fields `uOpt`  and `uFile` in `system.cfg` ([Security model description](Security-model-description))
  1. Generate passwords using `genPass` component ([genPass tool](../components/authentication))
  1. Configure technical user in `access.cfg` ([Security model description](Security-model-description))
  1. Configure ordinary users in `access.cfg` ([Security model description](Security-model-description))
  1. Refresh users’ permissions using `authentication` component ([authentication/refreshUFiles tool](../components/authentication))
  1. Restart the system ([yak restart command](../tutorial/Installation))

### Refreshing permissions’ settings
  - see [Lesson05](../tutorial/Lesson05)
  - Processes affected by permissions’ changes can be restarted after refresh
  - Description in the dev doc
