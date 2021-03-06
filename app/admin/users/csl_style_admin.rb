# -*- encoding : utf-8 -*-

ActiveAdmin.register Users::CslStyle do
  menu parent: 'admin_settings'
  filter :name

  index do
    column :name
    actions
  end

  # :nocov:
  controller do
    def permitted_params
      params.permit users_csl_style: [:name, :style]
    end
  end
  # :nocov:
end
