namespace 'db' do
  desc "Loading all models and their methods in permissions table."
  task(:add_permissions => :environment) do
    arr = []
    controllers = Dir.new("#{Rails.root}/app/controllers").entries
    controllers.each do |entry|
      if entry =~ /_controller/
        arr << entry.camelize.gsub('.rb', '').constantize
      end
    end

    arr.each do |controller|
      if controller.permission
        manage_title = I18n.t(controller.controller_name + ".manage.title")
        write_permission(controller.permission, "manage", manage_title, manage_title) 
        controller.action_methods.each do |method|
          if method =~ /^([A-Za-z\d*]+)+([\w]*)+([A-Za-z\d*]+)$/
            name, cancan_action, action_desc = eval_cancan_action(controller.controller_name, method)
            write_permission(controller.permission, cancan_action, name, action_desc)  
          end
        end
      end
    end

    buyer_seller_role
  end
end

def eval_cancan_action(controller_name, action)
  case action.to_s
  when "new", "create"
    name = I18n.t(controller_name + ".new.title")
    cancan_action = "create"
  when "edit", "update"
    name = I18n.t(controller_name + ".edit.title")
    cancan_action = "edit"
  when "delete", "destroy"
    name = "删除" 
    cancan_action = "destroy"
  else
    name = I18n.t(controller_name + "." + action.to_s + ".title")
    cancan_action = action.to_s
  end
  action_desc = name 

  return name, cancan_action, action_desc
end


def write_permission(class_name, cancan_action, name, description)
  permission  = Permission.where(["subject_class = ? and action = ?", class_name, cancan_action]).first 
  unless permission
    permission = Permission.new
    permission.subject_class =  class_name
    permission.action = cancan_action
    permission.name = name
    permission.description = description
    permission.save
  else
    permission.name = name 
    permission.description = description
    permission.save
  end
end

def buyer_seller_role
  admin_class = [Setting.admins.class_name, Setting.users.class_name, Setting.roles.class_name]
  seller_class = [Setting.shops.class_name, Setting.products.class_name]

  buyer_permissions = Permission.where(["action = ? and subject_class not in (?)", "manage", admin_class.concat(seller_class)])
  seller_permissions = Permission.where(["action = ? and subject_class in (?)", "manage", seller_class])

  buyer_role = Role.where(:name => Setting.roles.new_buyer).first
  unless buyer_role
    buyer_role = Role.create(:name => Setting.roles.new_buyer)
  end
  buyer_role.permissions = buyer_permissions

  seller_role = Role.where(:name => Setting.roles.new_seller).first
  unless seller_role
    seller_role = Role.create(:name => Setting.roles.new_seller)
  end
  seller_role.permissions = seller_permissions
end
