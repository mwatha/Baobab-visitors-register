require "composite_primary_keys"
class RolePrivilege < ActiveRecord::Base
  include Openmrs
  set_table_name "role_privilege"
  belongs_to :role, :foreign_key => :role
  belongs_to :privilege, :foreign_key => :privilege
  set_primary_keys :privilege, :role
end


### Original SQL Definition for role_privilege #### 
#   `role_id` int(11) NOT NULL ,
#   `privilege_id` int(11) NOT NULL ,
#   PRIMARY KEY  (`privilege_id`,`role_id`),
#   KEY `role_privilege` (`role_id`),
#   CONSTRAINT `privilege_definitons` FOREIGN KEY (`privilege_id`) REFERENCES `privilege` (`privilege_id`),
#   CONSTRAINT `role_privilege` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`)
